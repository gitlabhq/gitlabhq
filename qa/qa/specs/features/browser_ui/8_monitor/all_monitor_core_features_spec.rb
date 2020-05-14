# frozen_string_literal: true

module QA
  context 'Monitor', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/217705', type: :flaky } do
    describe 'with Prometheus Gitlab-managed cluster', :orchestrated, :kubernetes, :docker, :runner do
      before :all do
        Flow::Login.sign_in
        @project, @runner = deploy_project_with_prometheus
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
      end

      after :all do
        @runner.remove_via_api!
        @cluster.remove!
      end

      it 'configures custom metrics' do
        verify_add_custom_metric
        verify_edit_custom_metric
        verify_delete_custom_metric
      end

      it 'duplicates to create dashboard to custom' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |dashboard|
          dashboard.duplicate_dashboard

          expect(dashboard).to have_metrics
          expect(dashboard).to have_edit_dashboard_enabled
        end
      end

      it 'verifies data on filtered deployed environment' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |dashboard|
          dashboard.filter_environment

          expect(dashboard).to have_metrics
        end
      end

      it 'filters using the quick range' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |dashboard|
          dashboard.show_last('30 minutes')
          expect(dashboard).to have_metrics

          dashboard.show_last('3 hours')
          expect(dashboard).to have_metrics

          dashboard.show_last('1 day')
          expect(dashboard).to have_metrics
        end
      end

      private

      def deploy_project_with_prometheus
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'cluster-with-prometheus'
          project.description = 'Cluster with Prometheus'
        end

        runner = Resource::Runner.fabricate_via_api! do |runner|
          runner.project = project
          runner.name = project.name
        end

        @cluster = Service::KubernetesCluster.new.create!

        cluster_props = Resource::KubernetesCluster::ProjectCluster.fabricate! do |cluster_settings|
          cluster_settings.project = project
          cluster_settings.cluster = @cluster
          cluster_settings.install_helm_tiller = true
          cluster_settings.install_ingress = true
          cluster_settings.install_prometheus = true
        end

        Resource::CiVariable.fabricate_via_api! do |ci_variable|
          ci_variable.project = project
          ci_variable.key = 'AUTO_DEVOPS_DOMAIN'
          ci_variable.value = cluster_props.ingress_ip
          ci_variable.masked = false
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.directory = Pathname
                               .new(__dir__)
                               .join('../../../../fixtures/monitored_auto_devops')
          push.commit_message = 'Create AutoDevOps compatible Project for Monitoring'
        end

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_success_or_retry)

        [project, runner]
      end

      def verify_add_custom_metric
        Page::Project::Menu.perform(&:go_to_integrations_settings)
        Page::Project::Settings::Integrations.perform(&:click_on_prometheus_integration)

        Page::Project::Settings::Services::Prometheus.perform do |metrics_panel|
          metrics_panel.click_on_new_metric
          metrics_panel.add_custom_metric
        end

        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |dashboard|
          expect(dashboard).to have_custom_metric('HTTP Requests Total')
        end
      end

      def verify_edit_custom_metric
        Page::Project::Menu.perform(&:go_to_integrations_settings)
        Page::Project::Settings::Integrations.perform(&:click_on_prometheus_integration)
        Page::Project::Settings::Services::Prometheus.perform do |metrics_panel|
          metrics_panel.click_on_custom_metric('Business / HTTP Requests Total (req/sec)')
          metrics_panel.edit_custom_metric
        end

        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |dashboard|
          expect(dashboard).to have_custom_metric('Throughput')
        end
      end

      def verify_delete_custom_metric
        Page::Project::Menu.perform(&:go_to_integrations_settings)
        Page::Project::Settings::Integrations.perform(&:click_on_prometheus_integration)

        Page::Project::Settings::Services::Prometheus.perform do |metrics_panel|
          metrics_panel.click_on_custom_metric('Business / Throughput (req/sec)')
          metrics_panel.delete_custom_metric
        end

        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |dashboard|
          expect(dashboard).not_to have_custom_metric('Throughput')
        end
      end
    end
  end
end
