# frozen_string_literal: true

module QA
  RSpec.shared_context "cluster with Prometheus installed" do
    before :all do
      @cluster = Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::K3s).create!
      @project = Resource::Project.fabricate_via_api! do |project|
        project.name = 'monitoring-project'
        project.auto_devops_enabled = true
        project.template_name = 'express'
      end

      deploy_project_with_prometheus
    end

    def deploy_project_with_prometheus
      %w[
          CODE_QUALITY_DISABLED TEST_DISABLED LICENSE_MANAGEMENT_DISABLED
          SAST_DISABLED DAST_DISABLED DEPENDENCY_SCANNING_DISABLED
          CONTAINER_SCANNING_DISABLED BROWSER_PERFORMANCE_DISABLED SECRET_DETECTION_DISABLED
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
        cluster_settings.install_runner = true
        cluster_settings.install_ingress = true
        cluster_settings.install_prometheus = true
      end

      Resource::Pipeline.fabricate_via_api! do |pipeline|
        pipeline.project = @project
      end.visit!

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

    after :all do
      @cluster&.remove!
    end
  end
end
