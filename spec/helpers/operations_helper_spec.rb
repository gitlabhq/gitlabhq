# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OperationsHelper do
  include Gitlab::Routing

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }

  before do
    helper.instance_variable_set(:@project, project)
    allow(helper).to receive(:current_user) { user }
  end

  describe '#alerts_settings_data' do
    subject { helper.alerts_settings_data }

    before do
      allow(helper).to receive(:can?).with(user, :admin_operations, project) { true }
    end

    context 'initial integration configuration' do
      let_it_be(:prometheus_integration) { ::Integrations::Prometheus.new(project: project) }

      before do
        allow(project).to receive(:find_or_initialize_integration).and_call_original
        allow(project).to receive(:find_or_initialize_integration).with('prometheus').and_return(prometheus_integration)
      end

      it 'returns the correct values' do
        expect(subject).to eq(
          'alerts_setup_url' => help_page_path('operations/incident_management/integrations.md', anchor: 'configuration'),
          'alerts_usage_url' => project_alert_management_index_path(project),
          'prometheus_form_path' => project_service_path(project, prometheus_integration),
          'prometheus_reset_key_path' => reset_alerting_token_project_settings_operations_path(project),
          'prometheus_authorization_key' => nil,
          'prometheus_api_url' => nil,
          'prometheus_activated' => 'false',
          'prometheus_url' => notify_project_prometheus_alerts_url(project, format: :json),
          'disabled' => 'false',
          'project_path' => project.full_path,
          'multi_integrations' => 'false',
          'templates' => '[]',
          'create_issue' => 'false',
          'issue_template_key' => '',
          'send_email' => 'false',
          'auto_close_incident' => 'true',
          'operations_settings_endpoint' => project_settings_operations_path(project),
          'pagerduty_reset_key_path' => reset_pagerduty_token_project_settings_operations_path(project)
        )
      end
    end

    context 'with external Prometheus configured' do
      let_it_be(:prometheus_integration, reload: true) do
        create(:prometheus_integration, project: project)
      end

      context 'with external Prometheus enabled' do
        it 'returns the correct values' do
          expect(subject).to include(
            'prometheus_activated' => 'true',
            'prometheus_api_url' => prometheus_integration.api_url
          )
        end
      end

      context 'with external Prometheus disabled' do
        shared_examples 'Prometheus is disabled' do
          it 'returns the correct values' do
            expect(subject).to include(
              'prometheus_activated' => 'false',
              'prometheus_api_url' => prometheus_integration.api_url
            )
          end
        end

        let(:cluster_managed) { false }

        before do
          allow(prometheus_integration)
            .to receive(:prometheus_available?)
            .and_return(cluster_managed)

          prometheus_integration.update!(manual_configuration: false)
        end

        include_examples 'Prometheus is disabled'

        context 'when cluster managed' do
          let(:cluster_managed) { true }

          include_examples 'Prometheus is disabled'
        end
      end

      context 'with project alert setting' do
        let_it_be(:project_alerting_setting) { create(:project_alerting_setting, project: project) }

        it 'returns the correct values' do
          expect(subject).to include(
            'prometheus_authorization_key' => project_alerting_setting.token,
            'prometheus_api_url' => prometheus_integration.api_url
          )
        end
      end
    end
  end

  describe '#operations_settings_data' do
    let_it_be(:operations_settings) do
      create(
        :project_incident_management_setting,
        project: project,
        pagerduty_active: true
      )
    end

    subject { helper.operations_settings_data }

    it 'returns the correct set of data' do
      is_expected.to include(
        operations_settings_endpoint: project_settings_operations_path(project),
        pagerduty_active: 'true',
        pagerduty_token: operations_settings.pagerduty_token,
        pagerduty_webhook_url: project_incidents_integrations_pagerduty_url(project, token: operations_settings.pagerduty_token),
        pagerduty_reset_key_path: reset_pagerduty_token_project_settings_operations_path(project)
      )
    end
  end
end
