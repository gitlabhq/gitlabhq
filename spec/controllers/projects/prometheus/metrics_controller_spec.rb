require 'spec_helper'

describe Projects::Prometheus::MetricsController do
  let(:user) { create(:user) }
  let!(:project) { create(:project) }

  let(:prometheus_service) { double('prometheus_service') }

  before do
    allow(controller).to receive(:project).and_return(project)
    allow(project).to receive(:prometheus_service).and_return(prometheus_service)

    project.add_master(user)
    sign_in(user)
  end

  describe 'POST #validate_query' do
    context 'query is valid' do
      it 'confirms query is valid' do
        post :validate_query, project_params(format: :json, query: 'avg(metric)')

        expect(json_response).to eq("query_valid" => true)
      end
    end

    context 'query is invalid' do
      it 'confirms query is valid' do
        post :validate_query, project_params(format: :json, query: 'test(metric)')

        expect(json_response).to eq("query_valid" => false)
      end
    end
  end

  describe 'GET #active' do
    context 'when prometheus metrics are enabled' do
      context 'when data is not present' do
        before do
          allow(prometheus_service).to receive(:matched_metrics).and_return({})
        end

        it 'returns no content response' do
          get :active, project_params(format: :json)

          expect(response).to have_gitlab_http_status(204)
        end
      end

      context 'when data is available' do
        let(:sample_response) { { some_data: 1 } }

        before do
          allow(prometheus_service).to receive(:matched_metrics).and_return(sample_response)
        end

        it 'returns no content response' do
          get :active, project_params(format: :json)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to eq(sample_response.deep_stringify_keys)
        end
      end

      context 'when requesting non json response' do
        it 'returns not found response' do
          get :active, project_params

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'POST #create' do
    context 'metric is valid' do
      let(:valid_metric) { { prometheus_metric: { title: 'title', query: 'query' } } }

      it 'shows a success flash message' do
        post :create, project_params(valid_metric)

        expect(flash[:notice]).to include('Metric was successfully added.')
        expect(response).to redirect_to(edit_project_service_path(project, project.prometheus_service))
      end
    end

    context 'metric is invalid' do
      let(:invalid_metric) { { prometheus_metric: { title: 'title' } } }

      it 'returns an error' do
        post :create, project_params(invalid_metric)

        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
