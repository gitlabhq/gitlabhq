# frozen_string_literal: true

require 'spec_helper'

describe Projects::Environments::PrometheusApiController do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #proxy' do
    let(:prometheus_proxy_service) { instance_double(Prometheus::ProxyService) }

    let(:expected_params) do
      ActionController::Parameters.new(
        environment_params(
          proxy_path: 'query',
          controller: 'projects/environments/prometheus_api',
          action: 'proxy'
        )
      ).permit!
    end

    context 'with valid requests' do
      before do
        allow(Prometheus::ProxyService).to receive(:new)
          .with(environment, 'GET', 'query', expected_params)
          .and_return(prometheus_proxy_service)

        allow(prometheus_proxy_service).to receive(:execute)
          .and_return(service_result)
      end

      context 'with success result' do
        let(:service_result) { { status: :success, body: prometheus_body } }
        let(:prometheus_body) { '{"status":"success"}' }
        let(:prometheus_json_body) { JSON.parse(prometheus_body) }

        it 'returns prometheus response' do
          get :proxy, params: environment_params

          expect(Prometheus::ProxyService).to have_received(:new)
            .with(environment, 'GET', 'query', expected_params)
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq(prometheus_json_body)
        end

        context 'with format string' do
          before do
            expected_params[:query] = %{up{environment="#{environment.slug}"}}
          end

          it 'replaces variables with values' do
            get :proxy, params: environment_params.merge(query: 'up{environment="%{ci_environment_slug}"}')

            expect(Prometheus::ProxyService).to have_received(:new)
              .with(environment, 'GET', 'query', expected_params)
          end

          context 'with nil query' do
            let(:params_without_query) do
              environment_params.except(:query)
            end

            before do
              expected_params.delete(:query)
            end

            it 'does not raise error' do
              get :proxy, params: params_without_query

              expect(Prometheus::ProxyService).to have_received(:new)
                .with(environment, 'GET', 'query', expected_params)
            end
          end
        end

        context 'with variables' do
          let(:pod_name) { "pod1" }

          before do
            expected_params[:query] = %{up{pod_name="#{pod_name}"}}
            expected_params[:variables] = ['pod_name', pod_name]
          end

          it 'replaces variables with values' do
            get :proxy, params: environment_params.merge(
              query: 'up{pod_name="{{pod_name}}"}', variables: ['pod_name', pod_name]
            )

            expect(response).to have_gitlab_http_status(:success)
            expect(Prometheus::ProxyService).to have_received(:new)
              .with(environment, 'GET', 'query', expected_params)
          end

          context 'with invalid variables' do
            let(:params_with_invalid_variables) do
              environment_params.merge(
                query: 'up{pod_name="{{pod_name}}"}', variables: ['a']
              )
            end

            it 'returns 400' do
              get :proxy, params: params_with_invalid_variables

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(Prometheus::ProxyService).not_to receive(:new)
            end
          end
        end
      end

      context 'with nil result' do
        let(:service_result) { nil }

        it 'returns 204 no_content' do
          get :proxy, params: environment_params

          expect(json_response['status']).to eq(_('processing'))
          expect(json_response['message']).to eq(_('Not ready yet. Try again later.'))
          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'with 404 result' do
        let(:service_result) { { http_status: 404, status: :success, body: '{"body": "value"}' } }

        it 'returns body' do
          get :proxy, params: environment_params

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['body']).to eq('value')
        end
      end

      context 'with error result' do
        context 'with http_status' do
          let(:service_result) do
            { http_status: :service_unavailable, status: :error, message: 'error message' }
          end

          it 'sets the http response status code' do
            get :proxy, params: environment_params

            expect(response).to have_gitlab_http_status(:service_unavailable)
            expect(json_response['status']).to eq('error')
            expect(json_response['message']).to eq('error message')
          end
        end

        context 'without http_status' do
          let(:service_result) { { status: :error, message: 'error message' } }

          it 'returns bad_request' do
            get :proxy, params: environment_params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['status']).to eq('error')
            expect(json_response['message']).to eq('error message')
          end
        end
      end
    end

    context 'with inappropriate requests' do
      context 'with anonymous user' do
        before do
          sign_out(user)
        end

        it 'redirects to signin page' do
          get :proxy, params: environment_params

          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'without correct permissions' do
        before do
          project.team.truncate
        end

        it 'returns 404' do
          get :proxy, params: environment_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with invalid environment id' do
      let(:other_environment) { create(:environment) }

      it 'returns 404' do
        get :proxy, params: environment_params(id: other_environment.id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  private

  def environment_params(params = {})
    {
      id: environment.id.to_s,
      namespace_id: project.namespace.full_path,
      project_id: project.name,
      proxy_path: 'query',
      query: '1'
    }.merge(params)
  end
end
