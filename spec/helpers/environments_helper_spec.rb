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
        'settings_path' => edit_project_service_path(project, 'prometheus'),
        'clusters_path' => project_clusters_path(project),
        'metrics_dashboard_base_path' => environment_metrics_path(environment),
        'current_environment_name' => environment.name,
        'documentation_path' => help_page_path('administration/monitoring/prometheus/index.md'),
        'add_dashboard_documentation_path' => help_page_path('operations/metrics/dashboards/index.md', anchor: 'add-a-new-dashboard-to-your-project'),
        'empty_getting_started_svg_path' => match_asset_path('/assets/illustrations/monitoring/getting_started.svg'),
        'empty_loading_svg_path' => match_asset_path('/assets/illustrations/monitoring/loading.svg'),
        'empty_no_data_svg_path' => match_asset_path('/assets/illustrations/monitoring/no_data.svg'),
        'empty_unable_to_connect_svg_path' => match_asset_path('/assets/illustrations/monitoring/unable_to_connect.svg'),
        'metrics_endpoint' => additional_metrics_project_environment_path(project, environment, format: :json),
        'deployments_endpoint' => project_environment_deployments_path(project, environment, format: :json),
        'default_branch' => 'master',
        'project_path' => project_path(project),
        'tags_path' => project_tags_path(project),
        'has_metrics' => "#{environment.has_metrics?}",
        'external_dashboard_url' => nil,
        'environment_state' => environment.state,
        'custom_metrics_path' => project_prometheus_metrics_path(project),
        'validate_query_path' => validate_query_project_prometheus_metrics_path(project),
        'custom_metrics_available' => 'true',
        'alerts_endpoint' => project_prometheus_alerts_path(project, environment_id: environment.id, format: :json),
        'prometheus_alerts_available' => 'true',
        'custom_dashboard_base_path' => Gitlab::Metrics::Dashboard::RepoDashboardFinder::DASHBOARD_ROOT,
        'operations_settings_path' => project_settings_operations_path(project),
        'can_access_operations_settings' => 'true',
        'panel_preview_endpoint' => project_metrics_dashboards_builder_path(project, format: :json),
        'has_managed_prometheus' => 'false'
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
          'can_access_operations_settings' => 'false'
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
          'prometheus_alerts_available' => 'false'
        )
      end
    end

    context 'with metrics_setting' do
      before do
        create(:project_metrics_setting, project: project, external_dashboard_url: 'http://gitlab.com')
      end

      it 'adds external_dashboard_url' do
        expect(metrics_data['external_dashboard_url']).to eq('http://gitlab.com')
      end
    end

    context 'when the environment is not available' do
      before do
        environment.stop
      end

      subject { metrics_data }

      it { is_expected.to include('environment_state' => 'stopped') }
    end

    context 'when request is from project scoped metrics path' do
      let(:request) { double('request', path: path) }

      before do
        allow(helper).to receive(:request).and_return(request)
      end

      context '/:namespace/:project/-/metrics' do
        let(:path) { project_metrics_dashboard_path(project) }

        it 'uses correct path for metrics_dashboard_base_path' do
          expect(metrics_data['metrics_dashboard_base_path']).to eq(project_metrics_dashboard_path(project))
        end
      end

      context '/:namespace/:project/-/metrics/some_custom_dashboard.yml' do
        let(:path) { "#{project_metrics_dashboard_path(project)}/some_custom_dashboard.yml" }

        it 'uses correct path for metrics_dashboard_base_path' do
          expect(metrics_data['metrics_dashboard_base_path']).to eq(project_metrics_dashboard_path(project))
        end
      end
    end

    context 'has_managed_prometheus' do
      context 'without prometheus integration' do
        it "doesn't have managed prometheus" do
          expect(metrics_data).to include(
            'has_managed_prometheus' => 'false'
          )
        end
      end

      context 'with prometheus integration' do
        let_it_be(:prometheus_integration) { create(:prometheus_integration, project: project) }

        context 'when manual prometheus integration is active' do
          it "doesn't have managed prometheus" do
            prometheus_integration.update!(manual_configuration: true)

            expect(metrics_data).to include(
              'has_managed_prometheus' => 'false'
            )
          end
        end

        context 'when prometheus integration is inactive' do
          it "doesn't have managed prometheus" do
            prometheus_integration.update!(manual_configuration: false)

            expect(metrics_data).to include(
              'has_managed_prometheus' => 'false'
            )
          end
        end

        context 'when a cluster prometheus is available' do
          let(:cluster) { create(:cluster, projects: [project]) }

          it 'has managed prometheus' do
            create(:clusters_integrations_prometheus, cluster: cluster)

            expect(metrics_data).to include(
              'has_managed_prometheus' => 'true'
            )
          end
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
        "environment_name": environment.name,
        "environments_path": api_v4_projects_environments_path(id: project.id),
        "environment_id": environment.id,
        "cluster_applications_documentation_path" => help_page_path('user/clusters/integrations.md', anchor: 'elastic-stack-cluster-integration'),
        "clusters_path": project_clusters_path(project, format: :json)
      }

      expect(helper.environment_logs_data(project, environment)).to eq(expected_data)
    end
  end
end
