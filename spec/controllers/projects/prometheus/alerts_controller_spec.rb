# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::AlertsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:metric) { create(:prometheus_metric, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  shared_examples 'unprivileged' do
    before do
      project.add_developer(user)
    end

    it 'returns not_found' do
      make_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'project non-specific environment' do |status|
    let(:other) { create(:environment) }

    it "returns #{status}" do
      make_request(environment_id: other)

      expect(response).to have_gitlab_http_status(status)
    end

    if status == :ok
      it 'returns no prometheus alerts' do
        make_request(environment_id: other)

        expect(json_response).to be_empty
      end
    end
  end

  shared_examples 'project non-specific metric' do |status|
    let(:other) { create(:prometheus_alert) }

    it "returns #{status}" do
      make_request(id: other.prometheus_metric_id)

      expect(response).to have_gitlab_http_status(status)
    end
  end

  describe 'POST #notify' do
    let(:alert_1) { build(:alert_management_alert, :prometheus, project: project) }
    let(:alert_2) { build(:alert_management_alert, :prometheus, project: project) }
    let(:service_response) { ServiceResponse.success(http_status: :created) }
    let(:notify_service) { instance_double(Projects::Prometheus::Alerts::NotifyService, execute: service_response) }

    before do
      sign_out(user)

      expect(Projects::Prometheus::Alerts::NotifyService)
        .to receive(:new)
        .with(project, duck_type(:permitted?))
        .and_return(notify_service)
    end

    it 'returns created if notification succeeds' do
      expect(notify_service).to receive(:execute).and_return(service_response)

      post :notify, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:created)
    end

    it 'returns unprocessable entity if notification fails' do
      expect(notify_service).to receive(:execute).and_return(
        ServiceResponse.error(message: 'Unprocessable Entity', http_status: :unprocessable_entity)
      )

      post :notify, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    context 'bearer token' do
      context 'when set' do
        it 'extracts bearer token' do
          request.headers['HTTP_AUTHORIZATION'] = 'Bearer some token'

          expect(notify_service).to receive(:execute).with('some token')

          post :notify, params: project_params, as: :json
        end

        it 'pass nil if cannot extract a non-bearer token' do
          request.headers['HTTP_AUTHORIZATION'] = 'some token'

          expect(notify_service).to receive(:execute).with(nil)

          post :notify, params: project_params, as: :json
        end
      end

      context 'when missing' do
        it 'passes nil' do
          expect(notify_service).to receive(:execute).with(nil)

          post :notify, params: project_params, as: :json
        end
      end
    end
  end

  describe 'GET #metrics_dashboard' do
    let!(:alert) do
      create(:prometheus_alert, project: project, environment: environment, prometheus_metric: metric)
    end

    it 'returns a json object with the correct keys' do
      get :metrics_dashboard, params: request_params(id: metric.id, environment_id: alert.environment.id), format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.keys).to contain_exactly('dashboard', 'status', 'metrics_data')
    end

    it 'is the correct embed' do
      get :metrics_dashboard, params: request_params(id: metric.id, environment_id: alert.environment.id), format: :json

      title = json_response['dashboard']['panel_groups'][0]['panels'][0]['title']

      expect(title).to eq(metric.title)
    end

    it 'finds the first alert embed without environment_id' do
      get :metrics_dashboard, params: request_params(id: metric.id), format: :json

      title = json_response['dashboard']['panel_groups'][0]['panels'][0]['title']

      expect(title).to eq(metric.title)
    end

    it 'returns 404 for non-existant alerts' do
      get :metrics_dashboard, params: request_params(id: 0), format: :json

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end

  def request_params(opts = {}, defaults = {})
    project_params(opts.reverse_merge(defaults))
  end

  def alert_path(alert)
    project_prometheus_alert_path(
      project,
      alert.prometheus_metric_id,
      environment_id: alert.environment,
      format: :json
    )
  end
end
