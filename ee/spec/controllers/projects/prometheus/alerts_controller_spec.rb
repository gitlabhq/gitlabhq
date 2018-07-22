require 'spec_helper'

describe Projects::Prometheus::AlertsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:environment) { create(:environment, project: project) }
  let(:metric) { create(:prometheus_metric, project: project) }

  before do
    stub_licensed_features(prometheus_alerts: true)
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when project has no prometheus alert' do
      it 'renders forbidden when unlicensed' do
        stub_licensed_features(prometheus_alerts: false)

        get :index, project_params

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns an empty response' do
        get :index, project_params

        expect(response).to have_gitlab_http_status(200)
        expect(JSON.parse(response.body)).to be_empty
      end
    end

    context 'when project has prometheus alerts' do
      before do
        create_list(:prometheus_alert, 3, project: project, environment: environment)
      end

      it 'contains prometheus alerts' do
        get :index, project_params

        expect(response).to have_gitlab_http_status(200)
        expect(JSON.parse(response.body).count).to eq(3)
      end
    end
  end

  describe 'GET #show' do
    context 'when alert does not exist' do
      it 'renders 404' do
        get :show, project_params(id: PrometheusAlert.all.maximum(:prometheus_metric_id).to_i + 1)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when alert exists' do
      let(:alert) { create(:prometheus_alert, project: project, environment: environment, prometheus_metric: metric) }

      it 'renders forbidden when unlicensed' do
        stub_licensed_features(prometheus_alerts: false)

        get :show, project_params(id: alert.prometheus_metric_id)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders the alert' do
        alert_params = {
          "id" => alert.id,
          "title" => alert.title,
          "query" => alert.query,
          "operator" => alert.computed_operator,
          "threshold" => alert.threshold,
          "alert_path" => Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, alert.prometheus_metric_id, environment_id: alert.environment.id, format: :json)
        }

        get :show, project_params(id: alert.prometheus_metric_id)

        expect(response).to have_gitlab_http_status(200)
        expect(JSON.parse(response.body)).to include(alert_params)
      end
    end
  end

  describe 'POST #notify' do
    it 'sends a notification' do
      alert = create(:prometheus_alert, project: project, environment: environment, prometheus_metric: metric)
      notification_service = spy

      alert_params = {
        "alert" => alert.title,
        "expr" => "#{alert.query} #{alert.computed_operator} #{alert.threshold}",
        "for" => "5m",
        "labels" => {
          "gitlab" => "hook",
          "gitlab_alert_id" => alert.prometheus_metric_id
        }
      }

      allow(NotificationService).to receive(:new).and_return(notification_service)
      expect(notification_service).to receive_message_chain(:async, :prometheus_alerts_fired).with(project, [alert_params])

      post :notify, project_params(alerts: [alert])

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'POST #create' do
    it 'renders forbidden when unlicensed' do
      stub_licensed_features(prometheus_alerts: false)

      post :create, project_params(
        operator: ">",
        threshold: "1",
        environment_id: environment.id,
        prometheus_metric_id: metric.id
      )

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'creates a new prometheus alert' do
      schedule_update_service = spy
      alert_params = {
        "title" => metric.title,
        "query" => metric.query,
        "operator" => ">",
        "threshold" => 1.0
      }

      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)

      post :create, project_params(
        operator: ">",
        threshold: "1",
        environment_id: environment.id,
        prometheus_metric_id: metric.id
      )

      expect(schedule_update_service).to have_received(:execute)
      expect(response).to have_gitlab_http_status(200)
      expect(JSON.parse(response.body)).to include(alert_params)
    end
  end

  describe 'POST #update' do
    let(:schedule_update_service) { spy }
    let(:alert) { create(:prometheus_alert, project: project, environment: environment, prometheus_metric: metric) }

    before do
      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)
    end

    it 'renders forbidden when unlicensed' do
      stub_licensed_features(prometheus_alerts: false)

      put :update, project_params(id: alert.prometheus_metric_id, operator: "<")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'updates an already existing prometheus alert' do
      alert_params = {
        "id" => alert.id,
        "title" => alert.title,
        "query" => alert.query,
        "operator" => "<",
        "threshold" => alert.threshold,
        "alert_path" => Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, alert.prometheus_metric_id, environment_id: alert.environment.id, format: :json)
      }

      expect do
        put :update, project_params(id: alert.prometheus_metric_id, operator: "<")
      end.to change { alert.reload.operator }.to("lt")

      expect(schedule_update_service).to have_received(:execute)
      expect(response).to have_gitlab_http_status(200)
      expect(JSON.parse(response.body)).to include(alert_params)
    end
  end

  describe 'DELETE #destroy' do
    let(:schedule_update_service) { spy }
    let!(:alert) { create(:prometheus_alert, project: project, prometheus_metric: metric) }

    before do
      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)
    end

    it 'renders forbidden when unlicensed' do
      stub_licensed_features(prometheus_alerts: false)

      delete :destroy, project_params(id: alert.prometheus_metric_id)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'destroys the specified prometheus alert' do
      expect do
        delete :destroy, project_params(id: alert.prometheus_metric_id)
      end.to change { PrometheusAlert.count }.from(1).to(0)

      expect(schedule_update_service).to have_received(:execute)
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
