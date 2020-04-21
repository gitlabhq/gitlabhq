# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentsHelper do
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
        'current-environment-name' => environment.name,
        'documentation-path' => help_page_path('administration/monitoring/prometheus/index.md'),
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
        'prometheus-alerts-available' => 'true'
      )
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
end
