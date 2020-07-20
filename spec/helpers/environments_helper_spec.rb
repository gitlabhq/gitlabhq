# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentsHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }

  describe '#metrics_data' do
    before do
      # This is so that this spec also passes in EE.
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    let(:metrics_data) { helper.metrics_data(project, environment) }

    it 'returns data' do
      expect(metrics_data).to include(
        'settings-path' => edit_project_service_path(project, 'prometheus'),
        'clusters-path' => project_clusters_path(project),
        'metrics-dashboard-base-path' => environment_metrics_path(environment),
        'current-environment-name' => environment.name,
        'documentation-path' => help_page_path('administration/monitoring/prometheus/index.md'),
        'add-dashboard-documentation-path' => help_page_path('user/project/integrations/prometheus.md', anchor: 'adding-a-new-dashboard-to-your-project'),
        'empty-getting-started-svg-path' => match_asset_path('/assets/illustrations/monitoring/getting_started.svg'),
        'empty-loading-svg-path' => match_asset_path('/assets/illustrations/monitoring/loading.svg'),
        'empty-no-data-svg-path' => match_asset_path('/assets/illustrations/monitoring/no_data.svg'),
        'empty-unable-to-connect-svg-path' => match_asset_path('/assets/illustrations/monitoring/unable_to_connect.svg'),
        'metrics-endpoint' => additional_metrics_project_environment_path(project, environment, format: :json),
        'deployments-endpoint' => project_environment_deployments_path(project, environment, format: :json),
        'default-branch' => 'master',
        'project-path' => project_path(project),
        'tags-path' => project_tags_path(project),
        'has-metrics' => "#{environment.has_metrics?}",
        'prometheus-status' => "#{environment.prometheus_status}",
        'external-dashboard-url' => nil,
        'environment-state' => environment.state,
        'custom-metrics-path' => project_prometheus_metrics_path(project),
        'validate-query-path' => validate_query_project_prometheus_metrics_path(project),
        'custom-metrics-available' => 'true',
        'alerts-endpoint' => project_prometheus_alerts_path(project, environment_id: environment.id, format: :json),
        'prometheus-alerts-available' => 'true',
        'custom-dashboard-base-path' => Metrics::Dashboard::CustomDashboardService::DASHBOARD_ROOT,
        'operations-settings-path' => project_settings_operations_path(project),
        'can-access-operations-settings' => 'true'
      )
    end

    context 'without admin_operations permission' do
      before do
        allow(helper).to receive(:can?)
          .with(user, :admin_operations, project)
          .and_return(false)
      end

      specify do
        expect(metrics_data).to include(
          'can-access-operations-settings' => 'false'
        )
      end
    end

    context 'without read_prometheus_alerts permission' do
      before do
        allow(helper).to receive(:can?)
          .with(user, :read_prometheus_alerts, project)
          .and_return(false)
      end

      it 'returns false' do
        expect(metrics_data).to include(
          'prometheus-alerts-available' => 'false'
        )
      end
    end

    context 'with metrics_setting' do
      before do
        create(:project_metrics_setting, project: project, external_dashboard_url: 'http://gitlab.com')
      end

      it 'adds external_dashboard_url' do
        expect(metrics_data['external-dashboard-url']).to eq('http://gitlab.com')
      end
    end

    context 'when the environment is not available' do
      before do
        environment.stop
      end

      subject { metrics_data }

      it { is_expected.to include('environment-state' => 'stopped') }
    end

    context 'when request is from project scoped metrics path' do
      let(:request) { double('request', path: path) }

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      context '/:namespace/:project/-/metrics' do
        let(:path) { project_metrics_dashboard_path(project) }

        it 'uses correct path for metrics-dashboard-base-path' do
          expect(metrics_data['metrics-dashboard-base-path']).to eq(project_metrics_dashboard_path(project))
        end
      end

      context '/:namespace/:project/-/metrics/some_custom_dashboard.yml' do
        let(:path) { "#{project_metrics_dashboard_path(project)}/some_custom_dashboard.yml" }

        it 'uses correct path for metrics-dashboard-base-path' do
          expect(metrics_data['metrics-dashboard-base-path']).to eq(project_metrics_dashboard_path(project))
        end
      end
    end
  end

  describe '#custom_metrics_available?' do
    subject { helper.custom_metrics_available?(project) }

    before do
      project.add_maintainer(user)

      allow(helper).to receive(:current_user).and_return(user)

      allow(helper).to receive(:can?)
        .with(user, :admin_project, project)
        .and_return(true)
    end

    it 'returns true' do
      expect(subject).to eq(true)
    end
  end

  describe '#environment_logs_data' do
    it 'returns logs data' do
      expected_data = {
        "environment-name": environment.name,
        "environments-path": project_environments_path(project, format: :json),
        "environment-id": environment.id,
        "cluster-applications-documentation-path" => help_page_path('user/clusters/applications.md', anchor: 'elastic-stack'),
        "clusters-path": project_clusters_path(project, format: :json)
      }

      expect(helper.environment_logs_data(project, environment)).to eq(expected_data)
    end
  end
end
