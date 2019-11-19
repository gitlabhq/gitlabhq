# frozen_string_literal: true

require 'spec_helper'

describe Projects::ErrorTrackingHelper do
  include Gitlab::Routing.url_helpers

  set(:project) { create(:project) }
  set(:current_user) { create(:user) }

  describe '#error_tracking_data' do
    let(:can_enable_error_tracking) { true }
    let(:setting_path) { project_settings_operations_path(project) }

    let(:index_path) do
      project_error_tracking_index_path(project, format: :json)
    end

    before do
      allow(helper)
        .to receive(:can?)
        .with(current_user, :admin_operations, project)
        .and_return(can_enable_error_tracking)
    end

    context 'without error_tracking_setting' do
      it 'returns frontend configuration' do
        expect(helper.error_tracking_data(current_user, project)).to match(
          'index-path' => index_path,
          'user-can-enable-error-tracking' => 'true',
          'enable-error-tracking-link' => setting_path,
          'error-tracking-enabled' => 'false',
          'illustration-path' => match_asset_path('/assets/illustrations/cluster_popover.svg')
        )
      end
    end

    context 'with error_tracking_setting' do
      let(:error_tracking_setting) do
        create(:project_error_tracking_setting, project: project)
      end

      context 'when enabled' do
        before do
          error_tracking_setting.update!(enabled: true)
        end

        it 'show error tracking enabled' do
          expect(helper.error_tracking_data(current_user, project)).to include(
            'error-tracking-enabled' => 'true'
          )
        end
      end

      context 'when disabled' do
        before do
          error_tracking_setting.update!(enabled: false)
        end

        it 'show error tracking not enabled' do
          expect(helper.error_tracking_data(current_user, project)).to include(
            'error-tracking-enabled' => 'false'
          )
        end
      end
    end

    context 'when user is not maintainer' do
      let(:can_enable_error_tracking) { false }

      it 'shows error tracking enablement as disabled' do
        expect(helper.error_tracking_data(current_user, project)).to include(
          'user-can-enable-error-tracking' => 'false'
        )
      end
    end
  end

  describe '#error_details_data' do
    let(:issue_id) { 1234 }
    let(:route_params) { [project.owner, project, issue_id, { format: :json }] }
    let(:details_path) { details_namespace_project_error_tracking_index_path(*route_params) }
    let(:stack_trace_path) { stack_trace_namespace_project_error_tracking_index_path(*route_params) }

    let(:result) { helper.error_details_data(project, issue_id) }

    it 'returns the correct details path' do
      expect(result['issue-details-path']).to eq details_path
    end

    it 'returns the correct stack trace path' do
      expect(result['issue-stack-trace-path']).to eq stack_trace_path
    end
  end
end
