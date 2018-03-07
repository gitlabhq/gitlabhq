require 'spec_helper'

describe Projects::Prometheus::MetricsController do
  let(:user) { create(:user) }
  let(:project) { create(:prometheus_project) }

  let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }

  before do
    allow(controller).to receive(:project).and_return(project)
    allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)

    project.add_master(user)
    sign_in(user)
  end

  describe 'POST #validate_query' do
    before do
      allow(prometheus_adapter).to receive(:query).with(:validate, query) { validation_result }
    end

    let(:query) { 'avg(metric)' }

    context 'validation information is ready' do
      let(:validation_result) { { valid: true } }

      it 'validation data is returned' do
        post :validate_query, project_params(format: :json, query: query)

        expect(json_response).to eq('valid' => true)
      end
    end

    context 'validation information is not ready' do
      let(:validation_result) { {} }

      it 'validation data is returned' do
        post :validate_query, project_params(format: :json, query: query)

        expect(response).to have_gitlab_http_status(204)
      end
    end
  end

  describe 'GET #index' do
    context 'with custom metric present' do
      let!(:prometheus_metric) { create(:prometheus_metric, project: project) }

      it 'returns a list of metrics' do
        get :index, project_params(format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('prometheus/metrics', dir: 'ee')
      end
    end

    context 'without custom metrics ' do
      it 'returns an empty json' do
        get :index, project_params(format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to eq({})
      end
    end
  end

  describe 'POST #create' do
    context 'metric is valid' do
      let(:valid_metric) { { prometheus_metric: { title: 'title', query: 'query', group: 'business', y_label: 'label', unit: 'u', legend: 'legend' } } }

      it 'shows a success flash message' do
        post :create, project_params(valid_metric)

        expect(flash[:notice]).to include('Metric was successfully added.')

        expect(response).to redirect_to(edit_project_service_path(project, PrometheusService))
      end
    end

    context 'metric is invalid' do
      let(:invalid_metric) { { prometheus_metric: { title: 'title' } } }

      it 'renders new metric page' do
        post :create, project_params(invalid_metric)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template('new')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'format html' do
      let!(:metric) { create(:prometheus_metric, project: project) }

      it 'destroys the metric' do
        delete :destroy, project_params(id: metric.id)

        expect(response).to redirect_to(edit_project_service_path(project, PrometheusService))
        expect(PrometheusMetric.find_by(id: metric.id)).to be_nil
      end
    end

    context 'format json' do
      let!(:metric) { create(:prometheus_metric, project: project) }

      it 'destroys the metric' do
        delete :destroy, project_params(id: metric.id, format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(PrometheusMetric.find_by(id: metric.id)).to be_nil
      end
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
