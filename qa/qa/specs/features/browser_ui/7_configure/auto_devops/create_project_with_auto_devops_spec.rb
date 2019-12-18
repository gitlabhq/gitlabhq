# frozen_string_literal: true

require 'pathname'

module QA
  context 'Configure' do
    def disable_optional_jobs(project)
      # Disable code_quality check in Auto DevOps pipeline as it takes
      # too long and times out the test
      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'CODE_QUALITY_DISABLED'
        resource.value = '1'
        resource.masked = false
      end

      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'LICENSE_MANAGEMENT_DISABLED'
        resource.value = '1'
        resource.masked = false
      end

      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'SAST_DISABLED'
        resource.value = '1'
        resource.masked = false
      end

      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'DEPENDENCY_SCANNING_DISABLED'
        resource.value = '1'
        resource.masked = false
      end

      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'CONTAINER_SCANNING_DISABLED'
        resource.value = '1'
        resource.masked = false
      end

      Resource::CiVariable.fabricate_via_api! do |resource|
        resource.project = project
        resource.key = 'DAST_DISABLED'
        resource.value = '1'
        resource.masked = false
      end
    end

    # Failure issue: https://gitlab.com/gitlab-org/gitlab/issues/118481
    describe 'Auto DevOps support', :orchestrated, :kubernetes, :quarantine do
      context 'when rbac is enabled' do
        before(:all) do
          @cluster = Service::KubernetesCluster.new.create!
        end

        after(:all) do
          @cluster&.remove!
        end

        it 'runs auto devops' do
          Flow::Login.sign_in

          @project = Resource::Project.fabricate! do |p|
            p.name = Runtime::Env.auto_devops_project_name || 'project-with-autodevops'
            p.description = 'Project with Auto DevOps'
          end

          disable_optional_jobs(@project)

          # Set an application secret CI variable (prefixed with K8S_SECRET_)
          Resource::CiVariable.fabricate! do |resource|
            resource.project = @project
            resource.key = 'K8S_SECRET_OPTIONAL_MESSAGE'
            resource.value = 'you_can_see_this_variable'
            resource.masked = false
          end

          # Connect K8s cluster
          Resource::KubernetesCluster.fabricate! do |cluster|
            cluster.project = @project
            cluster.cluster = @cluster
            cluster.install_helm_tiller = true
            cluster.install_ingress = true
            cluster.install_prometheus = true
            cluster.install_runner = true
          end

          # Create Auto DevOps compatible repo
          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = @project
            push.directory = Pathname
              .new(__dir__)
              .join('../../../../../fixtures/auto_devops_rack')
            push.commit_message = 'Create Auto DevOps compatible rack application'
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

          Page::Project::Menu.perform(&:go_to_operations_environments)
          Page::Project::Operations::Environments::Index.perform do |index|
            index.click_environment_link('production')
          end
          Page::Project::Operations::Environments::Show.perform do |show|
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

        @project = Resource::Project.fabricate_via_browser_ui! do |p|
          p.name = "project-with-autodevops-#{SecureRandom.hex(8)}"
          p.description = 'Project with AutoDevOps'
        end

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CICD.perform(&:expand_auto_devops)
        Page::Project::Settings::AutoDevops.perform(&:enable_autodevops)

        @project.visit!

        # Create AutoDevOps repo
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../../fixtures/auto_devops_rack')
          push.commit_message = 'Create AutoDevOps compatible Project'
        end
      end

      it 'runs an AutoDevOps pipeline' do
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          expect(pipeline).to have_tag('Auto DevOps')
        end
      end
    end
  end
end
