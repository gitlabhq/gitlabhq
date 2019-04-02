# frozen_string_literal: true

require 'spec_helper'

describe Projects::Environments::PrometheusApiController do
  set(:project) { create(:project) }
  set(:environment) { create(:environment, project: project) }
  set(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #proxy' do
    let(:prometheus_proxy_service) { instance_double(Prometheus::ProxyService) }

    context 'with valid requests' do
      before do
        allow(Prometheus::ProxyService).to receive(:new)
          .with(environment, 'GET', 'query', anything)
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

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq(prometheus_json_body)
        end

        it 'filters params' do
          get :proxy, params: environment_params({ extra_param: 'dangerous value' })

          expect(Prometheus::ProxyService).to have_received(:new)
            .with(environment, 'GET', 'query', ActionController::Parameters.new({ 'query' => '1' }).permit!)
        end
      end

      context 'with nil result' do
        let(:service_result) { nil }

        it 'returns 202 accepted' do
          get :proxy, params: environment_params

          expect(json_response['status']).to eq('processing')
          expect(json_response['message']).to eq('Not ready yet. Try again later.')
          expect(response).to have_gitlab_http_status(:accepted)
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
  end

  private

  def environment_params(params = {})
    {
      id: environment.id,
      namespace_id: project.namespace,
      project_id: project,
      proxy_path: 'query',
      query: '1'
    }.reverse_merge(params)
  end
end
