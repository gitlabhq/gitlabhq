# frozen_string_literal: true

module QA
  RSpec.describe 'Package' do
    describe 'Package Registry', :skip_live_env, :orchestrated, :reliable, :packages, :object_storage, product_group: :package_registry do
      describe 'npm instance level endpoint' do
        using RSpec::Parameterized::TableSyntax
        include Runtime::Fixtures
        include Support::Helpers::MaskToken

        let!(:registry_scope) { Runtime::Namespace.sandbox_name }
        let!(:personal_access_token) do
          Flow::Login.sign_in unless Page::Main::Menu.perform(&:signed_in?)

          Resource::PersonalAccessToken.fabricate!.token
        end

        let(:project_deploy_token) do
          Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
            deploy_token.name = 'npm-deploy-token'
            deploy_token.project = project
            deploy_token.scopes = %w[
              read_repository
              read_package_registry
              write_package_registry
            ]
          end
        end

        let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
        let(:gitlab_address_with_port) { "#{uri.scheme}://#{uri.host}:#{uri.port}" }
        let(:gitlab_host_with_port) { "#{uri.host}:#{uri.port}" }

        let!(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'npm-instace-level-publish'
          end
        end

        let!(:another_project) do
          Resource::Project.fabricate_via_api! do |another_project|
            another_project.name = 'npm-instance-level-install'
            another_project.group = project.group
          end
        end

        let!(:runner) do
          Resource::GroupRunner.fabricate! do |runner|
            runner.name = "qa-runner-#{Time.now.to_i}"
            runner.tags = ["runner-for-#{project.group.name}"]
            runner.executor = :docker
            runner.group = project.group
          end
        end

        let(:package) do
          Resource::Package.init do |package|
            package.name = "@#{registry_scope}/#{project.name}-#{SecureRandom.hex(8)}"
            package.project = project
          end
        end

        after do
          package.remove_via_api!
          runner.remove_via_api!
          project.remove_via_api!
          another_project.remove_via_api!
        end

        where(:case_name, :authentication_token_type, :token_name, :testcase) do
          'using personal access token' | :personal_access_token | 'Personal Access Token' | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347600'
          'using ci job token'          | :ci_job_token          | 'CI Job Token'          | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347599'
          'using project deploy token'  | :project_deploy_token  | 'Deploy Token'          | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347598'
        end

        with_them do
          let(:auth_token) do
            case authentication_token_type
            when :personal_access_token
              use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: project)
              use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: another_project)
            when :ci_job_token
              '${CI_JOB_TOKEN}'
            when :project_deploy_token
              use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: project)
              use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: another_project)
            end
          end

          it 'push and pull a npm package via CI', testcase: params[:testcase] do
            Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
              npm_upload_yaml = ERB.new(read_fixture('package_managers/npm', 'npm_upload_package_instance.yaml.erb')).result(binding)
              package_json = ERB.new(read_fixture('package_managers/npm', 'package_instance.json.erb')).result(binding)

              Resource::Repository::Commit.fabricate_via_api! do |commit|
                commit.project = project
                commit.commit_message = 'Add files'
                commit.add_files([
                                   {
                                     file_path: '.gitlab-ci.yml',
                                     content: npm_upload_yaml
                                   },
                                   {
                                     file_path: 'package.json',
                                     content: package_json
                                   }
                                 ])
              end
            end

            project.visit!
            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('deploy')
            end

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
            end

            Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
              Resource::Repository::Commit.fabricate_via_api! do |commit|
                npm_install_yaml = ERB.new(read_fixture('package_managers/npm', 'npm_install_package_instance.yaml.erb')).result(binding)

                commit.project = another_project
                commit.commit_message = 'Add .gitlab-ci.yml'
                commit.add_files([
                                   {
                                     file_path: '.gitlab-ci.yml',
                                     content: npm_install_yaml
                                   }
                                 ])
              end
            end

            another_project.visit!
            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('install')
            end

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
              job.click_browse_button
            end

            Page::Project::Artifact::Show.perform do |artifacts|
              artifacts.go_to_directory('node_modules')
              artifacts.go_to_directory("@#{registry_scope}")
              expect(artifacts).to have_content(project.name.to_s)
            end

            project.visit!
            Page::Project::Menu.perform(&:go_to_package_registry)

            Page::Project::Packages::Index.perform do |index|
              expect(index).to have_package(package.name)

              index.click_package(package.name)
            end

            Page::Project::Packages::Show.perform do |show|
              expect(show).to have_package_info(package.name, "1.0.0")
            end
          end
        end
      end
    end
  end
end
