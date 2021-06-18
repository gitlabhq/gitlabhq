# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::MetricsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:prometheus_project) }

  let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET #active_common' do
    context 'when prometheus_adapter can query' do
      before do
        allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
      end

      context 'when prometheus metrics are enabled' do
        context 'when data is not present' do
          before do
            allow(prometheus_adapter).to receive(:query).with(:matched_metrics).and_return({})
          end

          it 'returns no content response' do
            get :active_common, params: project_params(format: :json)

            expect(response).to have_gitlab_http_status(:no_content)
          end
        end

        context 'when data is available' do
          let(:sample_response) { { some_data: 1 } }

          before do
            allow(prometheus_adapter).to receive(:query).with(:matched_metrics).and_return(sample_response)
          end

          it 'returns no content response' do
            get :active_common, params: project_params(format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq(sample_response.deep_stringify_keys)
          end
        end

        context 'when requesting non json response' do
          it 'returns not found response' do
            get :active_common, params: project_params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'when prometheus_adapter cannot query' do
      it 'renders 404' do
        prometheus_adapter = double('prometheus_adapter', can_query?: false)

        allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:query).with(:matched_metrics).and_return({})

        get :active_common, params: project_params(format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when prometheus_adapter is disabled' do
      let(:project) { create(:project) }

      it 'renders 404' do
        get :active_common, params: project_params(format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #validate_query' do
    before do
      allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
      allow(prometheus_adapter).to receive(:query).with(:validate, query) { validation_result }
    end

    let(:query) { 'avg(metric)' }

    context 'validation information is ready' do
      let(:validation_result) { { valid: true } }

      it 'validation data is returned' do
        post :validate_query, params: project_params(format: :json, query: query)

        expect(json_response).to eq('valid' => true)
      end
    end

    context 'validation information is not ready' do
      let(:validation_result) { nil }

      it 'validation data is returned' do
        post :validate_query, params: project_params(format: :json, query: query)

        expect(response).to have_gitlab_http_status(:accepted)
      end
    end
  end

  describe 'GET #index' do
    context 'with custom metric present' do
      let!(:prometheus_metric) { create(:prometheus_metric, project: project) }

      it 'returns a list of metrics' do
        get :index, params: project_params(format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('prometheus/metrics')
      end
    end

    context 'without custom metrics ' do
      it 'returns an empty json' do
        get :index, params: project_params(format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({})
      end
    end
  end

  describe 'POST #create' do
    context 'metric is valid' do
      let(:valid_metric) { { prometheus_metric: { title: 'title', query: 'query', group: 'business', y_label: 'label', unit: 'u', legend: 'legend' } } }

      it 'shows a success flash message' do
        post :create, params: project_params(valid_metric)

        expect(flash[:notice]).to include('Metric was successfully added.')

        expect(response).to redirect_to(edit_project_service_path(project, ::Integrations::Prometheus))
      end
    end

    context 'metric is invalid' do
      let(:invalid_metric) { { prometheus_metric: { title: 'title' } } }

      it 'renders new metric page' do
        post :create, params: project_params(invalid_metric)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('new')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'format html' do
      let!(:metric) { create(:prometheus_metric, project: project) }

      it 'destroys the metric' do
        delete :destroy, params: project_params(id: metric.id)

        expect(response).to redirect_to(edit_project_service_path(project, ::Integrations::Prometheus))
        expect(PrometheusMetric.find_by(id: metric.id)).to be_nil
      end
    end

    context 'format json' do
      let!(:metric) { create(:prometheus_metric, project: project) }

      it 'destroys the metric' do
        delete :destroy, params: project_params(id: metric.id, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(PrometheusMetric.find_by(id: metric.id)).to be_nil
      end
    end
  end

  describe '#prometheus_adapter' do
    before do
      allow(controller).to receive(:project).and_return(project)
    end

    it 'calls prometheus adapter service' do
      expect_next_instance_of(::Gitlab::Prometheus::Adapter) do |instance|
        expect(instance).to receive(:prometheus_adapter)
      end

      subject.__send__(:prometheus_adapter)
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
