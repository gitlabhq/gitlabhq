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

  describe 'GET #index' do
    def make_request(opts = {})
      get :index, params: request_params(opts, environment_id: environment)
    end

    context 'when project has no prometheus alert' do
      it 'returns an empty response' do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    context 'when project has prometheus alerts' do
      let(:production) { create(:environment, project: project) }
      let(:staging) { create(:environment, project: project) }
      let(:json_alert_ids) { json_response.map { |alert| alert['id'] } }

      let!(:production_alerts) do
        create_list(:prometheus_alert, 2, project: project, environment: production)
      end

      let!(:staging_alerts) do
        create_list(:prometheus_alert, 1, project: project, environment: staging)
      end

      it 'contains prometheus alerts only for the production environment' do
        make_request(environment_id: production)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(2)
        expect(json_alert_ids).to eq(production_alerts.map(&:id))
      end

      it 'contains prometheus alerts only for the staging environment' do
        make_request(environment_id: staging)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(1)
        expect(json_alert_ids).to eq(staging_alerts.map(&:id))
      end

      it 'does not return prometheus alerts without environment' do
        make_request(environment_id: nil)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end
    end

    it_behaves_like 'unprivileged'
    it_behaves_like 'project non-specific environment', :ok
  end

  describe 'GET #show' do
    let(:alert) do
      create(:prometheus_alert,
             :with_runbook_url,
             project: project,
             environment: environment,
             prometheus_metric: metric)
    end

    def make_request(opts = {})
      get :show, params: request_params(
        opts,
        id: alert.prometheus_metric_id,
        environment_id: environment
      )
    end

    context 'when alert does not exist' do
      it 'returns not_found' do
        make_request(id: 0)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when alert exists' do
      let(:alert_params) do
        {
          'id' => alert.id,
          'title' => alert.title,
          'query' => alert.query,
          'operator' => alert.computed_operator,
          'threshold' => alert.threshold,
          'runbook_url' => alert.runbook_url,
          'alert_path' => alert_path(alert)
        }
      end

      it 'renders the alert' do
        make_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(alert_params)
      end

      it_behaves_like 'unprivileged'
      it_behaves_like 'project non-specific environment', :not_found
      it_behaves_like 'project non-specific metric', :not_found
    end
  end

  describe 'POST #notify' do
    let(:service_response) { ServiceResponse.success }
    let(:notify_service) { instance_double(Projects::Prometheus::Alerts::NotifyService, execute: service_response) }

    before do
      sign_out(user)

      expect(Projects::Prometheus::Alerts::NotifyService)
        .to receive(:new)
        .with(project, nil, duck_type(:permitted?))
        .and_return(notify_service)
    end

    it 'returns ok if notification succeeds' do
      expect(notify_service).to receive(:execute).and_return(ServiceResponse.success)

      post :notify, params: project_params, session: { as: :json }

      expect(response).to have_gitlab_http_status(:ok)
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

  describe 'POST #create' do
    let(:schedule_update_service) { spy }

    let(:alert_params) do
      {
        'title' => metric.title,
        'query' => metric.query,
        'operator' => '>',
        'threshold' => 1.0,
        'runbook_url' => 'https://sample.runbook.com'
      }
    end

    def make_request(opts = {})
      post :create, params: request_params(
        opts,
        operator: '>',
        threshold: '1',
        runbook_url: 'https://sample.runbook.com',
        environment_id: environment,
        prometheus_metric_id: metric
      )
    end

    it 'creates a new prometheus alert' do
      allow(::Clusters::Applications::ScheduleUpdateService)
        .to receive(:new).and_return(schedule_update_service)

      make_request

      expect(schedule_update_service).to have_received(:execute)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(alert_params)
    end

    it 'returns bad_request for an invalid metric' do
      make_request(prometheus_metric_id: 'invalid')

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it_behaves_like 'unprivileged'
    it_behaves_like 'project non-specific environment', :bad_request
  end

  describe 'PUT #update' do
    let(:schedule_update_service) { spy }

    let(:alert) do
      create(:prometheus_alert,
             project: project,
             environment: environment,
             prometheus_metric: metric)
    end

    let(:alert_params) do
      {
        'id' => alert.id,
        'title' => alert.title,
        'query' => alert.query,
        'operator' => '<',
        'threshold' => alert.threshold,
        'alert_path' => alert_path(alert)
      }
    end

    before do
      allow(::Clusters::Applications::ScheduleUpdateService)
        .to receive(:new).and_return(schedule_update_service)
    end

    def make_request(opts = {})
      put :update, params: request_params(
        opts,
        id: alert.prometheus_metric_id,
        operator: '<',
        environment_id: alert.environment
      )
    end

    it 'updates an already existing prometheus alert' do
      expect { make_request(operator: '<') }
        .to change { alert.reload.operator }.to('lt')

      expect(schedule_update_service).to have_received(:execute)
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(alert_params)
    end

    it 'returns bad_request for an invalid alert data' do
      make_request(runbook_url: 'bad-url')

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it_behaves_like 'unprivileged'
    it_behaves_like 'project non-specific environment', :not_found
    it_behaves_like 'project non-specific metric', :not_found
  end

  describe 'DELETE #destroy' do
    let(:schedule_update_service) { spy }

    let!(:alert) do
      create(:prometheus_alert, project: project, prometheus_metric: metric)
    end

    before do
      allow(::Clusters::Applications::ScheduleUpdateService)
        .to receive(:new).and_return(schedule_update_service)
    end

    def make_request(opts = {})
      delete :destroy, params: request_params(
        opts,
        id: alert.prometheus_metric_id,
        environment_id: alert.environment
      )
    end

    it 'destroys the specified prometheus alert' do
      expect { make_request }.to change { PrometheusAlert.count }.by(-1)

      expect(schedule_update_service).to have_received(:execute)
    end

    it_behaves_like 'unprivileged'
    it_behaves_like 'project non-specific environment', :not_found
    it_behaves_like 'project non-specific metric', :not_found
  end

  describe 'GET #metrics_dashboard' do
    let!(:alert) do
      create(:prometheus_alert,
             project: project,
             environment: environment,
             prometheus_metric: metric)
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
