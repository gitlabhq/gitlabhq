# frozen_string_literal: true

require 'pathname'

module QA
  RSpec.describe 'Configure' do
    let(:project) do
      Resource::Project.fabricate_via_api! do |project|
        project.name = Runtime::Env.auto_devops_project_name || 'autodevops-project'
        project.auto_devops_enabled = true
      end
    end

    before do
      disable_optional_jobs(project)
    end

    describe 'Auto DevOps support', :orchestrated, :kubernetes, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/251090', type: :stale } do
      context 'when rbac is enabled' do
        let(:cluster) { Service::KubernetesCluster.new.create! }

        after do
          cluster&.remove!
        end

        it 'runs auto devops', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1715' do
          Flow::Login.sign_in

          # Set an application secret CI variable (prefixed with K8S_SECRET_)
          Resource::CiVariable.fabricate! do |resource|
            resource.project = project
            resource.key = 'K8S_SECRET_OPTIONAL_MESSAGE'
            resource.value = 'you_can_see_this_variable'
            resource.masked = false
          end

          # Connect K8s cluster
          Resource::KubernetesCluster::ProjectCluster.fabricate! do |k8s_cluster|
            k8s_cluster.project = project
            k8s_cluster.cluster = cluster
            k8s_cluster.install_ingress = true
            k8s_cluster.install_prometheus = true
            k8s_cluster.install_runner = true
          end

          # Create Auto DevOps compatible repo
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

          Page::Project::Menu.perform(&:go_to_deployments_environments)
          Page::Project::Deployments::Environments::Index.perform do |index|
            index.click_environment_link('production')
          end
          Page::Project::Deployments::Environments::Show.perform do |show|
            show.view_deployment do
              expect(page).to have_content('Hello World!')
              expect(page).to have_content('you_can_see_this_variable')
            end
          end
        end
      end
    end

    describe 'Auto DevOps', :smoke do
      before do
        Flow::Login.sign_in

        project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CICD.perform(&:expand_auto_devops)
        Page::Project::Settings::AutoDevops.perform(&:enable_autodevops)

        # Create AutoDevOps repo
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../../fixtures/auto_devops_rack')
          push.commit_message = 'Create AutoDevOps compatible Project'
        end
      end

      it 'runs an AutoDevOps pipeline', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1847' do
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          expect(pipeline).to have_tag('Auto DevOps')
        end
      end
    end

    private

    def disable_optional_jobs(project)
      %w[
        CODE_QUALITY_DISABLED LICENSE_MANAGEMENT_DISABLED
        SAST_DISABLED DAST_DISABLED DEPENDENCY_SCANNING_DISABLED
        CONTAINER_SCANNING_DISABLED
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
