# frozen_string_literal: true

module QA
  RSpec.describe 'Configure',
    only: { pipeline: %i[staging staging-canary canary production] }, product_group: :configure do
    describe 'Auto DevOps with a Kubernetes Agent' do
      let!(:app_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'autodevops-app-project'
          project.template_name = 'express'
          project.auto_devops_enabled = true
        end
      end

      let!(:cluster) { Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::Gcloud).create! }

      let!(:kubernetes_agent) do
        Resource::Clusters::Agent.fabricate_via_api! do |agent|
          agent.name = 'agent1'
          agent.project = app_project
        end
      end

      let!(:agent_token) do
        Resource::Clusters::AgentToken.fabricate_via_api! do |token|
          token.agent = kubernetes_agent
        end
      end

      before do
        cluster.install_kubernetes_agent(agent_token.token)
        upload_agent_config(app_project, kubernetes_agent.name)

        set_kube_ingress_base_domain(app_project)
        set_kube_context(app_project)
        disable_optional_jobs(app_project)
      end

      after do
        cluster&.remove!
      end

      it 'runs auto devops', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348061' do
        Flow::Login.sign_in

        app_project.visit!

        Page::Project::Menu.perform(&:go_to_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_run_pipeline_button)
        Page::Project::Pipeline::New.perform(&:click_run_pipeline_button)

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
          expect(job).to be_successful(timeout: 600)
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

    def set_kube_context(project)
      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'KUBE_CONTEXT'
        resource.value = "#{project.path_with_namespace}:#{kubernetes_agent.name}"
        resource.masked = false
      end
    end

    def upload_agent_config(project, agent)
      Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add kubernetes agent configuration'
          commit.add_files(
            [
              {
                file_path: ".gitlab/agents/#{agent}/config.yaml",
                content: <<~YAML
                  ci_access:
                    projects:
                      - id: #{project.path_with_namespace}
                YAML
              }
            ]
          )
        end
      end
    end

    def disable_optional_jobs(project)
      %w[
        TEST_DISABLED CODE_QUALITY_DISABLED LICENSE_MANAGEMENT_DISABLED
        BROWSER_PERFORMANCE_DISABLED LOAD_PERFORMANCE_DISABLED
        SAST_DISABLED SECRET_DETECTION_DISABLED DEPENDENCY_SCANNING_DISABLED
        CONTAINER_SCANNING_DISABLED DAST_DISABLED REVIEW_DISABLED
        CODE_INTELLIGENCE_DISABLED CLUSTER_IMAGE_SCANNING_DISABLED
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
