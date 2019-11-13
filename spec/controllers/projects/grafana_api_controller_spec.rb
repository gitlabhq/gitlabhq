# frozen_string_literal: true

require 'spec_helper'

describe Projects::GrafanaApiController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #proxy' do
    let(:proxy_service) { instance_double(Grafana::ProxyService) }
    let(:params) do
      {
        namespace_id: project.namespace.full_path,
        project_id: project.name,
        proxy_path: 'api/v1/query_range',
        datasource_id: '1',
        query: 'rate(relevant_metric)',
        start: '1570441248',
        end: '1570444848',
        step: '900'
      }
    end

    before do
      allow(Grafana::ProxyService).to receive(:new).and_return(proxy_service)
      allow(proxy_service).to receive(:execute).and_return(service_result)
    end

    shared_examples_for 'error response' do |http_status|
      it "returns #{http_status}" do
        get :proxy, params: params

        expect(response).to have_gitlab_http_status(http_status)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('error message')
      end
    end

    context 'with a successful result' do
      let(:service_result) { { status: :success, body: '{}' } }

      it 'returns a grafana datasource response' do
        get :proxy, params: params

        expect(Grafana::ProxyService)
          .to have_received(:new)
          .with(project, '1', 'api/v1/query_range',
                params.slice(:query, :start, :end, :step).stringify_keys)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({})
      end
    end

    context 'when the request is still unavailable' do
      let(:service_result) { nil }

      it 'returns 204 no content' do
        get :proxy, params: params

        expect(response).to have_gitlab_http_status(:no_content)
        expect(json_response['status']).to eq('processing')
        expect(json_response['message']).to eq('Not ready yet. Try again later.')
      end
    end

    context 'when an error has occurred' do
      context 'with an error accessing grafana' do
        let(:service_result) do
          {
            http_status: :service_unavailable,
            status: :error,
            message: 'error message'
          }
        end

        it_behaves_like 'error response', :service_unavailable
      end

      context 'with a processing error' do
        let(:service_result) do
          {
            status: :error,
            message: 'error message'
          }
        end

        it_behaves_like 'error response', :bad_request
      end
    end
  end

  describe 'GET #metrics_dashboard' do
    let(:service_result) { { status: :success, dashboard: '{}' } }
    let(:params) do
      {
        format: :json,
        embedded: true,
        grafana_url: 'https://grafana.example.com',
        namespace_id: project.namespace.full_path,
        project_id: project.name
      }
    end

    before do
      allow(Gitlab::Metrics::Dashboard::Finder)
      .to receive(:find)
      .and_return(service_result)
    end

    context 'when the result is still processing' do
      let(:service_result) { nil }

      it 'returns 204 no content' do
        get :metrics_dashboard, params: params

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when the result was successful' do
      it 'returns the dashboard response' do
        get :metrics_dashboard, params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({
          'dashboard' => '{}',
          'status' => 'success'
        })
      end
    end

    context 'when an error has occurred' do
      shared_examples_for 'error response' do |http_status|
        it "returns #{http_status}" do
          get :metrics_dashboard, params: params

          expect(response).to have_gitlab_http_status(http_status)
          expect(json_response['status']).to eq('error')
          expect(json_response['message']).to eq('error message')
        end
      end

      context 'with an error accessing grafana' do
        let(:service_result) do
          {
            http_status: :service_unavailable,
            status: :error,
            message: 'error message'
          }
        end

        it_behaves_like 'error response', :service_unavailable
      end

      context 'with a processing error' do
        let(:service_result) { { status: :error, message: 'error message' } }

        it_behaves_like 'error response', :bad_request
      end
    end
  end
end
