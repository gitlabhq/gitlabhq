# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OperationsHelper do
  include Gitlab::Routing

  describe '#alerts_settings_data' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project, reload: true) { create(:project) }

    subject { helper.alerts_settings_data }

    before do
      helper.instance_variable_set(:@project, project)
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:can?).with(user, :admin_operations, project) { true }
    end

    context 'initial service configuration' do
      let_it_be(:alerts_service) { AlertsService.new(project: project) }
      let_it_be(:prometheus_service) { PrometheusService.new(project: project) }

      before do
        allow(project).to receive(:find_or_initialize_service).with('alerts').and_return(alerts_service)
        allow(project).to receive(:find_or_initialize_service).with('prometheus').and_return(prometheus_service)
      end

      it 'returns the correct values' do
        expect(subject).to eq(
          'activated' => 'false',
          'url' => alerts_service.url,
          'authorization_key' => nil,
          'form_path' => project_service_path(project, alerts_service),
          'alerts_setup_url' => help_page_path('user/project/integrations/generic_alerts.md', anchor: 'setting-up-generic-alerts'),
          'alerts_usage_url' => project_alert_management_index_path(project),
          'prometheus_form_path' => project_service_path(project, prometheus_service),
          'prometheus_reset_key_path' => reset_alerting_token_project_settings_operations_path(project),
          'prometheus_authorization_key' => nil,
          'prometheus_api_url' => nil,
          'prometheus_activated' => 'false',
          'prometheus_url' => notify_project_prometheus_alerts_url(project, format: :json)
        )
      end
    end

    context 'with external Prometheus configured' do
      let_it_be(:prometheus_service, reload: true) do
        create(:prometheus_service, project: project)
      end

      context 'with external Prometheus enabled' do
        it 'returns the correct values' do
          expect(subject).to include(
            'prometheus_activated' => 'true',
            'prometheus_api_url' => prometheus_service.api_url
          )
        end
      end

      context 'with external Prometheus disabled' do
        shared_examples 'Prometheus is disabled' do
          it 'returns the correct values' do
            expect(subject).to include(
              'prometheus_activated' => 'false',
              'prometheus_api_url' => prometheus_service.api_url
            )
          end
        end

        let(:cluster_managed) { false }

        before do
          allow(prometheus_service)
            .to receive(:prometheus_available?)
            .and_return(cluster_managed)

          prometheus_service.update!(manual_configuration: false)
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
            'prometheus_api_url' => prometheus_service.api_url
          )
        end
      end
    end

    context 'with generic alerts service configured' do
      let_it_be(:alerts_service) { create(:alerts_service, project: project) }

      context 'with generic alerts enabled' do
        it 'returns the correct values' do
          expect(subject).to include(
            'activated' => 'true',
            'authorization_key' => alerts_service.token,
            'url' => alerts_service.url
          )
        end
      end

      context 'with generic alerts disabled' do
        before do
          alerts_service.update!(active: false)
        end

        it 'returns the correct values' do
          expect(subject).to include(
            'activated' => 'false',
            'authorization_key' => alerts_service.token
          )
        end
      end
    end
  end
end
