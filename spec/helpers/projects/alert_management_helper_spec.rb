# frozen_string_literal: true

require 'spec_helper'

describe Projects::AlertManagementHelper do
  include Gitlab::Routing.url_helpers

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_path) { project.full_path }

  describe '#alert_management_data' do
    let(:user_can_enable_alert_management) { true }
    let(:setting_path) { edit_project_service_path(project, AlertsService) }

    subject(:data) { helper.alert_management_data(current_user, project) }

    before do
      allow(helper)
        .to receive(:can?)
        .with(current_user, :admin_project, project)
        .and_return(user_can_enable_alert_management)
    end

    context 'without alert_managements_setting' do
      it 'returns index page configuration' do
        expect(helper.alert_management_data(current_user, project)).to match(
          'project-path' => project_path,
          'enable-alert-management-path' => setting_path,
          'empty-alert-svg-path' => match_asset_path('/assets/illustrations/alert-management-empty-state.svg'),
          'user-can-enable-alert-management' => 'true',
          'alert-management-enabled' => 'false'
        )
      end
    end

    context 'with alerts service' do
      let_it_be(:alerts_service) { create(:alerts_service, project: project) }

      context 'when alerts service is active' do
        it 'enables alert management' do
          expect(data).to include(
            'alert-management-enabled' => 'true'
          )
        end
      end

      context 'when alerts service is inactive' do
        it 'disables alert management' do
          alerts_service.update(active: false)

          expect(data).to include(
            'alert-management-enabled' => 'false'
          )
        end
      end
    end

    context 'when user does not have requisite enablement permissions' do
      let(:user_can_enable_alert_management) { false }

      it 'shows error tracking enablement as disabled' do
        expect(helper.alert_management_data(current_user, project)).to include(
          'user-can-enable-alert-management' => 'false'
        )
      end
    end
  end

  describe '#alert_management_detail_data' do
    let(:alert_id) { 1 }
    let(:new_issue_path) { new_project_issue_path(project) }

    it 'returns detail page configuration' do
      expect(helper.alert_management_detail_data(project, alert_id)).to eq(
        'alert-id' => alert_id,
        'project-path' => project_path,
        'new-issue-path' => new_issue_path
      )
    end
  end
end
