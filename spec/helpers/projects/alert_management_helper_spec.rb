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
          'empty-alert-svg-path' => match_asset_path('/assets/illustrations/alert-management-empty-state.svg'),
          'user-can-enable-alert-management' => 'true',
          'alert-management-enabled' => 'false',
          'has-managed-prometheus' => 'false',
          'text-query': nil,
          'assignee-username-query': nil
        )
      end
    end

    context 'with prometheus integration' do
      let_it_be(:prometheus_integration) { create(:prometheus_integration, project: project) }

      context 'when manual prometheus integration is active' do
        it "enables alert management and doesn't show managed prometheus" do
          prometheus_integration.update!(manual_configuration: true)

          expect(data).to include(
            'alert-management-enabled' => 'true'
          )
          expect(data).to include(
            'has-managed-prometheus' => 'false'
          )
        end
      end

      context 'when a cluster prometheus is available' do
        let(:cluster) { create(:cluster, projects: [project]) }

        it 'has managed prometheus' do
          create(:clusters_integrations_prometheus, cluster: cluster)

          expect(data).to include(
            'has-managed-prometheus' => 'true'
          )
        end
      end

      context 'when prometheus integration is inactive' do
        it 'disables alert management and hides managed prometheus' do
          prometheus_integration.update!(manual_configuration: false)

          expect(data).to include(
            'alert-management-enabled' => 'false'
          )
          expect(data).to include(
            'has-managed-prometheus' => 'false'
          )
        end
      end
    end

    context 'without prometheus integration' do
      it "doesn't have managed prometheus" do
        expect(data).to include(
          'has-managed-prometheus' => 'false'
        )
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

    it 'returns detail page configuration' do
      expect(helper.alert_management_detail_data(project, alert_id)).to eq(
        'alert-id' => alert_id,
        'project-path' => project_path,
        'project-id' => project_id,
        'project-issues-path' => issues_path,
        'page' => 'OPERATIONS'
      )
    end
  end
end
