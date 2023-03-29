# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Environments::PrometheusApiController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:proxyable) { create(:environment, project: project) }

  before do
    project.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #prometheus_proxy' do
    it_behaves_like 'metrics dashboard prometheus api proxy' do
      let(:proxyable_params) do
        {
          id: proxyable.id.to_s,
          namespace_id: project.namespace.full_path,
          project_id: project.name
        }
      end

      context 'with variables' do
        let(:prometheus_body) { '{"status":"success"}' }
        let(:pod_name) { "pod1" }

        before do
          expected_params[:query] = %{up{pod_name="#{pod_name}"}}
          expected_params[:variables] = { 'pod_name' => pod_name }
        end

        it 'replaces variables with values' do
          get :prometheus_proxy, params: prometheus_proxy_params.merge(
            query: 'up{pod_name="{{pod_name}}"}', variables: { 'pod_name' => pod_name }
          )

          expect(response).to have_gitlab_http_status(:success)
          expect(Prometheus::ProxyService).to have_received(:new)
                                                .with(proxyable, 'GET', 'query', expected_params)
        end

        context 'with invalid variables' do
          let(:params_with_invalid_variables) do
            prometheus_proxy_params.merge(
              query: 'up{pod_name="{{pod_name}}"}', variables: ['a']
            )
          end

          it 'returns 400' do
            get :prometheus_proxy, params: params_with_invalid_variables

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(Prometheus::ProxyService).not_to receive(:new)
          end
        end
      end

      context 'with anonymous user' do
        let(:prometheus_body) { nil }

        before do
          sign_out(user)
        end

        it 'redirects to signin page' do
          get :prometheus_proxy, params: prometheus_proxy_params

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end
end
