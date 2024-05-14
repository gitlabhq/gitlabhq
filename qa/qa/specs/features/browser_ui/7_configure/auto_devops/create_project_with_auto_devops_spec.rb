# frozen_string_literal: true

module QA
  RSpec.describe 'Configure',
    only: { pipeline: %i[staging staging-canary canary production] }, product_group: :environments do
    describe 'Auto DevOps with a Kubernetes Agent' do
      let!(:app_project) { create(:project, :auto_devops, name: 'autodevops-app-project', template_name: 'express') }
      let!(:cluster) { Service::KubernetesCluster.new(provider_class: Service::ClusterProvider::Gcloud).create! }
      let!(:kubernetes_agent) { create(:cluster_agent, name: 'agent1', project: app_project) }
      let!(:agent_token) { create(:cluster_agent_token, agent: kubernetes_agent) }

      before do
        cluster.install_kubernetes_agent(agent_token.token, kubernetes_agent.name)
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

          job.go_to_pipeline
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
      create(:ci_variable, project: project, key: 'KUBE_INGRESS_BASE_DOMAIN', value: 'example.com')
    end

    def set_kube_context(project)
      create(:ci_variable,
        project: project,
        key: 'KUBE_CONTEXT',
        value: "#{project.path_with_namespace}:#{kubernetes_agent.name}")
    end

    def upload_agent_config(project, agent)
      Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
        create(:commit, project: project, commit_message: 'Add k8s agent configuration', actions: [
          {
            action: 'create',
            file_path: ".gitlab/agents/#{agent}/config.yaml",
            content: <<~YAML
              ci_access:
                projects:
                  - id: #{project.path_with_namespace}
            YAML
          }
        ])
      end
    end

    def disable_optional_jobs(project)
      %w[
        TEST_DISABLED CODE_QUALITY_DISABLED
        BROWSER_PERFORMANCE_DISABLED LOAD_PERFORMANCE_DISABLED
        SAST_DISABLED SECRET_DETECTION_DISABLED DEPENDENCY_SCANNING_DISABLED
        CONTAINER_SCANNING_DISABLED DAST_DISABLED REVIEW_DISABLED
        CODE_INTELLIGENCE_DISABLED CLUSTER_IMAGE_SCANNING_DISABLED
      ].each do |key|
        create(:ci_variable, project: project, key: key, value: '1')
      end
    end
  end
end
