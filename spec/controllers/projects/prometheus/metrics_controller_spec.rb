require 'spec_helper'

describe Projects::Prometheus::MetricsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:prometheus_service) { double('prometheus_service') }

  before do
    allow(controller).to receive(:project).and_return(project)
    allow(project).to receive(:find_or_initialize_service).with('prometheus').and_return(prometheus_service)

    project.add_master(user)
    sign_in(user)
  end

  describe 'GET #active_common' do
    context 'when prometheus metrics are enabled' do
      context 'when data is not present' do
        before do
          allow(prometheus_service).to receive(:matched_metrics).and_return({})
        end

        it 'returns no content response' do
          get :active_common, project_params(format: :json)

          expect(response).to have_gitlab_http_status(204)
        end
      end

      context 'when data is available' do
        let(:sample_response) { { some_data: 1 } }

        before do
          allow(prometheus_service).to receive(:matched_metrics).and_return(sample_response)
        end

        it 'returns no content response' do
          get :active_common, project_params(format: :json)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to eq(sample_response.deep_stringify_keys)
        end
      end

      context 'when requesting non json response' do
        it 'returns not found response' do
          get :active_common, project_params

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
