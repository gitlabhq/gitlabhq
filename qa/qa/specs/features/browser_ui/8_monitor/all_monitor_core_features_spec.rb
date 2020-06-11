# frozen_string_literal: true

module QA
  context 'Monitor' do
    describe 'with Prometheus in a Gitlab-managed cluster', :orchestrated, :kubernetes do
      before :all do
        @cluster = Service::KubernetesCluster.new.create!
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'monitoring-project'
          project.auto_devops_enabled = true
        end

        deploy_project_with_prometheus
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
      end

      after :all do
        @cluster.remove!
      end

      it 'configures custom metrics' do
        verify_add_custom_metric
        verify_edit_custom_metric
        verify_delete_custom_metric
      end

      it 'duplicates to create dashboard to custom' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          on_dashboard.duplicate_dashboard

          expect(on_dashboard).to have_metrics
          expect(on_dashboard).to have_edit_dashboard_enabled
        end
      end

      it 'verifies data on filtered deployed environment' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          on_dashboard.filter_environment

          expect(on_dashboard).to have_metrics
        end
      end

      it 'filters using the quick range' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          on_dashboard.show_last('30 minutes')
          expect(on_dashboard).to have_metrics

          on_dashboard.show_last('3 hours')
          expect(on_dashboard).to have_metrics

          on_dashboard.show_last('1 day')
          expect(on_dashboard).to have_metrics
        end
      end

      private

      def deploy_project_with_prometheus
        %w[
          CODE_QUALITY_DISABLED TEST_DISABLED LICENSE_MANAGEMENT_DISABLED
          SAST_DISABLED DAST_DISABLED DEPENDENCY_SCANNING_DISABLED
          CONTAINER_SCANNING_DISABLED PERFORMANCE_DISABLED
        ].each do |key|
          Resource::CiVariable.fabricate_via_api! do |resource|
            resource.project = @project
            resource.key = key
            resource.value = '1'
            resource.masked = false
          end
        end

        Flow::Login.sign_in

        Resource::KubernetesCluster::ProjectCluster.fabricate! do |cluster_settings|
          cluster_settings.project = @project
          cluster_settings.cluster = @cluster
          cluster_settings.install_helm_tiller = true
          cluster_settings.install_runner = true
          cluster_settings.install_ingress = true
          cluster_settings.install_prometheus = true
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
                               .new(__dir__)
                               .join('../../../../fixtures/auto_devops_rack')
          push.commit_message = 'Create AutoDevOps compatible Project for Monitoring'
        end

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('build')
        end
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 600)

          job.click_element(:pipeline_path)
        end

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('production')
        end
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 1200)

          job.click_element(:pipeline_path)
        end
      end

      def verify_add_custom_metric
        Page::Project::Menu.perform(&:go_to_integrations_settings)
        Page::Project::Settings::Integrations.perform(&:click_on_prometheus_integration)

        Page::Project::Settings::Services::Prometheus.perform do |metrics_panel|
          metrics_panel.click_on_new_metric
          metrics_panel.add_custom_metric
        end

        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          expect(on_dashboard).to have_custom_metric('HTTP Requests Total')
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

        Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          expect(on_dashboard).to have_custom_metric('Throughput')
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

        Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          expect(on_dashboard).not_to have_custom_metric('Throughput')
        end
      end
    end
  end
end
