# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Alerting::NotificationsController, feature_category: :incident_management do
  include HttpBasicAuthHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:params) { project_params }

  describe 'POST #create' do
    around do |example|
      ForgeryProtection.with_forgery_protection { example.run }
    end

    shared_examples 'process alert payload' do |notify_service_class|
      let(:notify_service) { instance_double(notify_service_class, execute: service_response) }

      before do
        allow(notify_service_class).to receive(:new).and_return(notify_service)
      end

      def make_request
        post :create, params: params, body: payload.to_json, as: :json
      end

      context 'when notification service succeeds' do
        let(:permitted_params) { ActionController::Parameters.new(payload).permit! }

        it 'responds with the alert data' do
          make_request

          if service_response.payload.present?
            expect(json_response).to contain_exactly(
              { 'iid' => alert_1.iid, 'title' => alert_1.title },
              { 'iid' => alert_2.iid, 'title' => alert_2.title }
            )
          end

          expect(response).to have_gitlab_http_status(service_response.http_status)
        end

        it 'does not pass excluded parameters to the notify service' do
          make_request

          expect(notify_service_class)
            .to have_received(:new)
            .with(project, permitted_params)
        end
      end

      context 'when notification service fails' do
        let(:service_response) { ServiceResponse.error(message: 'Unauthorized', http_status: :unauthorized) }

        it 'responds with the service response' do
          make_request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      shared_examples 'a working token' do
        it 'extracts token' do
          expect(notify_service).to receive(:execute).with('some token', nil)

          make_request
        end

        context 'with a corresponding project_alerting_setting' do
          let_it_be_with_reload(:setting) { create(:project_alerting_setting, :with_http_integration, project: project) }
          let_it_be_with_reload(:integration) { project.alert_management_http_integrations.last! }

          context 'and a migrated or synced HTTP integration' do
            it 'extracts and finds the integration' do
              expect(notify_service).to receive(:execute).with('some token', integration)

              make_request
            end
          end

          context 'and no migrated or synced HTTP integration' do
            before do
              integration.destroy!
            end

            it 'does not find an integration' do
              expect(notify_service).to receive(:execute).with('some token', nil)

              make_request
            end
          end
        end

        context 'with a corresponding integration' do
          context 'with integration parameters specified' do
            let_it_be_with_reload(:integration) { create(:alert_management_http_integration, project: project) }

            let(:params) { project_params(endpoint_identifier: integration.endpoint_identifier, name: integration.name) }

            context 'the integration is active' do
              it 'extracts and finds the integration' do
                expect(notify_service).to receive(:execute).with('some token', integration)

                make_request
              end
            end

            context 'when the integration is inactive' do
              before do
                integration.update!(active: false)
              end

              it 'does not find an integration' do
                expect(notify_service).to receive(:execute).with('some token', nil)

                make_request
              end
            end
          end

          context 'without integration parameters specified' do
            let_it_be(:integration) { create(:alert_management_http_integration, :legacy, project: project) }

            it 'extracts and finds the legacy integration' do
              expect(notify_service).to receive(:execute).with('some token', integration)

              make_request
            end
          end
        end
      end

      context 'with bearer token' do
        context 'when set' do
          before do
            request.headers.merge(build_token_auth_header('some token'))
          end

          it_behaves_like 'a working token'
        end
      end

      context 'with basic auth token' do
        before do
          request.headers.merge basic_auth_header(nil, 'some token')
        end

        it_behaves_like 'a working token'
      end

      context 'when inextractable token' do
        it 'passes nil for a non-bearer token' do
          request.headers['HTTP_AUTHORIZATION'] = 'some token'

          expect(notify_service).to receive(:execute).with(nil, nil)

          make_request
        end
      end

      context 'when missing token' do
        it 'passes nil' do
          expect(notify_service).to receive(:execute).with(nil, nil)

          make_request
        end
      end
    end

    context 'with generic alert payload' do
      it_behaves_like 'process alert payload', Projects::Alerting::NotifyService do
        let(:alert_1) { build(:alert_management_alert, project: project) }
        let(:alert_2) { build(:alert_management_alert, project: project) }
        let(:service_response) { ServiceResponse.success(payload: { alerts: [alert_1, alert_2] }) }
        let(:payload) { { title: 'Alert title' } }
      end
    end

    context 'with Prometheus alert payload' do
      include PrometheusHelpers

      it_behaves_like 'process alert payload', Projects::Prometheus::Alerts::NotifyService do
        let(:service_response) { ServiceResponse.success(http_status: :created) }
        let(:payload) { prometheus_alert_payload }
      end
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
