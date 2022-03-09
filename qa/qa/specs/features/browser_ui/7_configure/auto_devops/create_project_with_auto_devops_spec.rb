# frozen_string_literal: true

module QA
  RSpec.describe 'Configure', only: { subdomain: :staging } do
    let(:project) do
      Resource::Project.fabricate_via_api! do |project|
        project.name = 'autodevops-project'
        project.auto_devops_enabled = true
      end
    end

    before do
      set_kube_ingress_base_domain(project)
      disable_optional_jobs(project)
    end

    describe 'Auto DevOps support' do
      context 'when rbac is enabled' do
        let(:cluster) { Service::KubernetesCluster.new.create! }

        after do
          cluster&.remove!
          project.remove_via_api!
        end

        it 'runs auto devops', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348061' do
          Flow::Login.sign_in

          Resource::KubernetesCluster::ProjectCluster.fabricate! do |k8s_cluster|
            k8s_cluster.project = project
            k8s_cluster.cluster = cluster
            k8s_cluster.install_ingress = true
          end

          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.directory = Pathname
              .new(__dir__)
              .join('../../../../../fixtures/auto_devops_rack')
            push.commit_message = 'Create Auto DevOps compatible rack application'
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('build')
          end
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 600)

            job.click_element(:pipeline_path)
          end

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('test')
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
      end
    end

    private

    def set_kube_ingress_base_domain(project)
      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'KUBE_INGRESS_BASE_DOMAIN'
        resource.value = 'example.com'
        resource.masked = false
      end
    end

    def disable_optional_jobs(project)
      %w[
        CODE_QUALITY_DISABLED LICENSE_MANAGEMENT_DISABLED
        SAST_DISABLED DAST_DISABLED DEPENDENCY_SCANNING_DISABLED
        CONTAINER_SCANNING_DISABLED BROWSER_PERFORMANCE_DISABLED
        SECRET_DETECTION_DISABLED
      ].each do |key|
        Resource::CiVariable.fabricate_via_api! do |resource|
          resource.project = project
          resource.key = key
          resource.value = '1'
          resource.masked = false
        end
      end
    end
  end
end
