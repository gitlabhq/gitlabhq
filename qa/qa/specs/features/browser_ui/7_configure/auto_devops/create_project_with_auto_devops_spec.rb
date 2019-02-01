# frozen_string_literal: true

require 'pathname'

module QA
  # Transient failure issue: https://gitlab.com/gitlab-org/quality/nightly/issues/68
  context 'Configure', :orchestrated, :kubernetes, :quarantine do
    describe 'Auto DevOps support' do
      def login
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }
      end

      [true, false].each do |rbac|
        context "when rbac is #{rbac ? 'enabled' : 'disabled'}" do
          before(:all) do
            login

            @project = Resource::Project.fabricate! do |p|
              p.name = Runtime::Env.auto_devops_project_name || 'project-with-autodevops'
              p.description = 'Project with Auto DevOps'
            end

            # Disable code_quality check in Auto DevOps pipeline as it takes
            # too long and times out the test
            Resource::CiVariable.fabricate! do |resource|
              resource.project = @project
              resource.key = 'CODE_QUALITY_DISABLED'
              resource.value = '1'
            end

            # Create Auto DevOps compatible repo
            Resource::Repository::ProjectPush.fabricate! do |push|
              push.project = @project
              push.directory = Pathname
                .new(__dir__)
                .join('../../../../../fixtures/auto_devops_rack')
              push.commit_message = 'Create Auto DevOps compatible rack application'
            end

            Page::Project::Show.act { wait_for_push }

            # Create and connect K8s cluster
            @cluster = Service::KubernetesCluster.new(rbac: rbac).create!
            kubernetes_cluster = Resource::KubernetesCluster.fabricate! do |cluster|
              cluster.project = @project
              cluster.cluster = @cluster
              cluster.install_helm_tiller = true
              cluster.install_ingress = true
              cluster.install_prometheus = true
              cluster.install_runner = true
            end

            kubernetes_cluster.populate(:ingress_ip)

            @project.visit!
            Page::Project::Menu.act { click_ci_cd_settings }
            Page::Project::Settings::CICD.perform do |p|
              p.enable_auto_devops_with_domain(
                "#{kubernetes_cluster.ingress_ip}.nip.io")
            end
          end

          after(:all) do
            @cluster&.remove!
          end

          before do
            login
          end

          it 'runs auto devops' do
            @project.visit!
            Page::Project::Menu.act { click_ci_cd_pipelines }
            Page::Project::Pipeline::Index.act { go_to_latest_pipeline }

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.go_to_job('build')
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_sucessful(timeout: 600), "Job did not pass"

              job.click_element(:pipeline_path)
            end

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.go_to_job('test')
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_sucessful(timeout: 600), "Job did not pass"

              job.click_element(:pipeline_path)
            end

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.go_to_job('production')
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_sucessful(timeout: 1200), "Job did not pass"

              job.click_element(:pipeline_path)
            end

            Page::Project::Menu.act { click_operations_environments }
            Page::Project::Operations::Environments::Index.perform do |index|
              index.go_to_environment('production')
            end
            Page::Project::Operations::Environments::Show.perform do |show|
              show.view_deployment do
                expect(page).to have_content('Hello World!')
              end
            end
          end

          it 'user sets application secret variable and Auto DevOps passes it to container' do
            # Set an application secret CI variable (prefixed with K8S_SECRET_)
            Resource::CiVariable.fabricate! do |resource|
              resource.project = @project
              resource.key = 'K8S_SECRET_OPTIONAL_MESSAGE'
              resource.value = 'You can see this application secret'
            end

            # Our current Auto DevOps implementation won't update the production
            # app if we only update a CI variable with no code change.
            #
            # Workaround: push new code and use the resultant pipeline.
            Resource::Repository::ProjectPush.fabricate! do |push|
              push.project = @project
              push.commit_message = 'Force a Deployment change by pushing new code'
              push.file_name = 'new_file.txt'
              push.file_content = 'new file contents'
            end

            @project.visit!
            Page::Project::Menu.act { click_ci_cd_pipelines }
            Page::Project::Pipeline::Index.act { go_to_latest_pipeline }

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.go_to_job('build')
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_sucessful(timeout: 600), "Job did not pass"

              job.click_element(:pipeline_path)
            end

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.go_to_job('test')
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_sucessful(timeout: 600), "Job did not pass"

              job.click_element(:pipeline_path)
            end

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.go_to_job('production')
            end
            Page::Project::Job::Show.perform do |job|
              expect(job).to be_sucessful(timeout: 1200), "Job did not pass"

              job.click_element(:pipeline_path)
            end

            Page::Project::Menu.act { click_operations_environments }

            Page::Project::Operations::Environments::Index.perform do |index|
              index.go_to_environment('production')
            end

            Page::Project::Operations::Environments::Show.perform do |show|
              show.view_deployment do
                expect(page).to have_content('Hello World!')
                expect(page).to have_content('You can see this application secret')
              end
            end
          end
        end
      end
    end
  end
end
