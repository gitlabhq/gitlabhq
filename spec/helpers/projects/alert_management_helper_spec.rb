# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AlertManagementHelper do
  include Gitlab::Routing.url_helpers

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:project_path) { project.full_path }
  let(:project_id) { project.id }

  describe '#alert_management_data' do
    let(:user_can_enable_alert_management) { true }
    let(:setting_path) { project_settings_operations_path(project, anchor: 'js-alert-management-settings') }

    subject(:data) { helper.alert_management_data(current_user, project) }

    before do
      allow(helper)
        .to receive(:can?)
        .with(current_user, :admin_operations, project)
        .and_return(user_can_enable_alert_management)
    end

    context 'without alert_managements_setting' do
      it 'returns index page configuration' do
        expect(helper.alert_management_data(current_user, project)).to match(
          'project-path' => project_path,
          'enable-alert-management-path' => setting_path,
          'alerts-help-url' => 'http://test.host/help/operations/incident_management/alerts.md',
          'populating-alerts-help-url' => 'http://test.host/help/operations/incident_management/integrations.md#configuration',
          'empty-alert-svg-path' => match_asset_path('/assets/illustrations/empty-state/empty-scan-alert-md.svg'),
          'user-can-enable-alert-management' => 'true',
          'alert-management-enabled' => 'false',
          'text-query': nil,
          'assignee-username-query': nil
        )
      end
    end

    context 'with prometheus integration' do
      let_it_be(:prometheus_integration) { create(:prometheus_integration, project: project) }

      context 'when manual prometheus integration is active' do
        it "enables alert management" do
          prometheus_integration.update!(manual_configuration: true)

          expect(data).to include(
            'alert-management-enabled' => 'true'
          )
        end
      end

      context 'when prometheus service is inactive' do
        it 'disables alert management' do
          prometheus_integration.update!(manual_configuration: false)

          expect(data).to include(
            'alert-management-enabled' => 'false'
          )
        end
      end
    end

    context 'with http integration' do
      let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

      context 'when integration is active' do
        it 'enables alert management' do
          expect(data).to include(
            'alert-management-enabled' => 'true'
          )
        end
      end

      context 'when integration is inactive' do
        it 'disables alert management' do
          integration.update!(active: false)

          expect(data).to include(
            'alert-management-enabled' => 'false'
          )
        end
      end
    end

    context 'with an alert' do
      let_it_be(:alert) { create(:alert_management_alert, project: project) }

      it 'enables alert management' do
        expect(data).to include(
          'alert-management-enabled' => 'true'
        )
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
    let(:issues_path) { project_issues_path(project) }
    let(:details_alert_management_path) { details_project_alert_management_path(project, alert_id) }
    let(:can_update_alert) { true }

    before do
      allow(helper)
        .to receive(:can?)
        .with(current_user, :update_alert_management_alert, project)
        .and_return(can_update_alert)
    end

    it 'returns detail page configuration' do
      expect(helper.alert_management_detail_data(current_user, project, alert_id)).to eq(
        'alert-id' => alert_id,
        'project-path' => project_path,
        'project-id' => project_id,
        'project-issues-path' => issues_path,
        'project-alert-management-details-path' => details_alert_management_path,
        'page' => 'OPERATIONS',
        'can-update' => 'true'
      )
    end

    context 'when user cannot update alert' do
      let(:can_update_alert) { false }

      it 'shows error tracking enablement as disabled' do
        expect(helper.alert_management_detail_data(current_user, project, alert_id)).to include(
          'can-update' => 'false'
        )
      end
    end
  end
end
