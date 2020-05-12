# frozen_string_literal: true

module QA
  context 'Monitor' do
    describe 'Dashboards', :orchestrated, :kubernetes, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29262', type: :waiting_on } do
      before(:all) do
        @cluster = Service::KubernetesCluster.new.create!
        Flow::Login.sign_in
        create_project_to_monitor
        wait_for_deployment
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
      end

      after(:all) do
        @cluster&.remove!
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

      def wait_for_deployment
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_success_or_retry)
        Page::Project::Menu.perform(&:go_to_operations_metrics)
      end

      def create_project_to_monitor
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'cluster-with-prometheus'
          project.description = 'Cluster with Prometheus'
        end

        @cluster_props = Resource::KubernetesCluster::ProjectCluster.fabricate_via_browser_ui! do |cluster_settings|
          cluster_settings.project = @project
          cluster_settings.cluster = @cluster
          cluster_settings.install_helm_tiller = true
          cluster_settings.install_ingress = true
          cluster_settings.install_prometheus = true
        end

        Resource::CiVariable.fabricate_via_api! do |ci_variable|
          ci_variable.project = @project
          ci_variable.key = 'AUTO_DEVOPS_DOMAIN'
          ci_variable.value = @cluster_props.ingress_ip
          ci_variable.masked = false
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
                               .new(__dir__)
                               .join('../../../../../fixtures/monitored_auto_devops')
          push.commit_message = 'Create AutoDevOps compatible Project for Monitoring'
        end
      end
    end
  end
end
