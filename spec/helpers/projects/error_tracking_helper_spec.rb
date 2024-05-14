# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ErrorTrackingHelper do
  include Gitlab::Routing.url_helpers

  let(:project) { build_stubbed(:project) }
  let(:current_user) { build_stubbed(:user) }

  describe '#error_tracking_data' do
    let(:can_enable_error_tracking) { true }
    let(:setting_path) { project_settings_operations_path(project) }
    let(:list_path) { project_error_tracking_index_path(project) }
    let(:project_path) { project.full_path }

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
          'integrated-error-tracking-enabled' => 'false',
          'list-path' => list_path,
          'project-path' => project_path,
          'illustration-path' => match_asset_path('/assets/illustrations/empty-state/empty-radar-md.svg'),
          'show-integrated-tracking-disabled-alert' => 'false'
        )
      end
    end

    context 'with error_tracking_setting' do
      let(:project) { build_stubbed(:project, :with_error_tracking_setting) }

      before do
        project.error_tracking_setting.enabled = enabled
      end

      context 'when enabled' do
        let(:enabled) { true }

        it 'show error tracking enabled' do
          expect(helper.error_tracking_data(current_user, project)).to include(
            'error-tracking-enabled' => 'true'
          )
        end
      end

      context 'when disabled' do
        let(:enabled) { false }

        it 'show error tracking not enabled' do
          expect(helper.error_tracking_data(current_user, project)).to include(
            'error-tracking-enabled' => 'false'
          )
        end
      end

      context 'with integrated error tracking feature' do
        using RSpec::Parameterized::TableSyntax

        where(:feature_flag, :enabled, :settings_integrated, :show_alert, :integrated_enabled) do
          false | true  | true  | true | false
          false | true  | false | false | false
          false | false | true  | false | false
          false | false | false | false | false
          true  | true  | true  | false | true
          true  | true  | false | false | false
          true  | false | true  | false | false
          true  | false | false | false | false
        end

        with_them do
          before do
            stub_feature_flags(integrated_error_tracking: feature_flag)

            project.error_tracking_setting.attributes = {
              enabled: enabled,
              integrated: settings_integrated
            }
          end

          specify do
            data = helper.error_tracking_data(current_user, project)
            expect(data).to include(
              'show-integrated-tracking-disabled-alert' => show_alert.to_s,
              'integrated-error-tracking-enabled' => integrated_enabled.to_s
            )
          end
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
    let(:project) { build_stubbed(:project, :with_error_tracking_setting) }
    let(:issue_id) { 1234 }
    let(:route_params) { [project.owner, project, issue_id, { format: :json }] }
    let(:project_path) { project.full_path }
    let(:stack_trace_path) { stack_trace_namespace_project_error_tracking_index_path(*route_params) }
    let(:issues_path) { project_issues_path(project) }

    let(:result) { helper.error_details_data(project, issue_id) }

    it 'returns the correct issue id' do
      expect(result['issue-id']).to eq issue_id
    end

    it 'returns the correct project path' do
      expect(result['project-path']).to eq project_path
    end

    it 'returns the correct stack trace path' do
      expect(result['issue-stack-trace-path']).to eq stack_trace_path
    end

    it 'creates an issue and redirects to issue show page' do
      expect(result['project-issues-path']).to eq issues_path
    end

    context 'with integrated error tracking feature' do
      using RSpec::Parameterized::TableSyntax

      where(:feature_flag, :enabled, :settings_integrated, :integrated_enabled) do
        false | true  | true   | false
        false | true  | false  | false
        false | false | true   | false
        false | false | false  | false
        true  | true  | true   | true
        true  | true  | false  | false
        true  | false | true   | false
        true  | false | false  | false
      end

      with_them do
        before do
          stub_feature_flags(integrated_error_tracking: feature_flag)

          project.error_tracking_setting.attributes = {
            enabled: enabled,
            integrated: settings_integrated
          }
        end

        specify do
          expect(result['integrated-error-tracking-enabled']).to eq integrated_enabled.to_s
        end
      end
    end
  end
end
