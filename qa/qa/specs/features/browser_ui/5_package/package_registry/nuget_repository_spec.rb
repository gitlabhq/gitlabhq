# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'NuGet Repository' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'nuget-package-project'
          project.template_name = 'dotnetcore'
          project.visibility = :private
        end
      end

      let(:personal_access_token) do
        unless Page::Main::Menu.perform(&:signed_in?)
          Flow::Login.sign_in
        end

        Resource::PersonalAccessToken.fabricate!
      end

      let(:group_deploy_token) do
        Resource::GroupDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'nuget-group-deploy-token'
          deploy_token.group = project.group
          deploy_token.scopes = %w[
            read_repository
            read_package_registry
            write_package_registry
          ]
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "dotnetcore-#{SecureRandom.hex(8)}"
          package.project = project
        end
      end

      let(:another_project) do
        Resource::Project.fabricate_via_api! do |another_project|
          another_project.name = 'nuget-package-install-project'
          another_project.template_name = 'dotnetcore'
          another_project.group = project.group
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.group.name}"]
          runner.executor = :docker
          runner.token = project.group.reload!.runners_token
        end
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
      end

      where(:authentication_token_type, :token_name) do
        :personal_access_token | 'Personal Access Token'
        :ci_job_token          | 'CI Job Token'
        :group_deploy_token    | 'Deploy Token'
      end

      with_them do
        let(:auth_token_password) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token.token}\""
          when :ci_job_token
            '${CI_JOB_TOKEN}'
          when :group_deploy_token
            "\"#{group_deploy_token.token}\""
          end
        end

        let(:auth_token_username) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token.user.username}\""
          when :ci_job_token
            'gitlab-ci-token'
          when :group_deploy_token
            "\"#{group_deploy_token.username}\""
          end
        end

        it "publishes a nuget package at the project level, installs and deletes it at the group level using a #{params[:token_name]}" do
          Flow::Login.sign_in

          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              nuget_upload_yaml = ERB.new(read_fixture('package_managers/nuget', 'nuget_upload_package.yaml.erb')).result(binding)
              commit.project = project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.update_files(
                [
                    {
                        file_path: '.gitlab-ci.yml',
                        content: nuget_upload_yaml
                    }
                ]
              )
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

          another_project.visit!

          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              nuget_install_yaml = ERB.new(read_fixture('package_managers/nuget', 'nuget_install_package.yaml.erb')).result(binding)

              commit.project = another_project
              commit.commit_message = 'Add new csproj file'
              commit.add_files(
                [
                    {
                        file_path: 'otherdotnet.csproj',
                        content: <<~EOF
                            <Project Sdk="Microsoft.NET.Sdk">

                              <PropertyGroup>
                                <OutputType>Exe</OutputType>
                                <TargetFramework>net5.0</TargetFramework>
                              </PropertyGroup>

                            </Project>
                        EOF
                    }
                ]
              )
              commit.update_files(
                [
                    {
                        file_path: '.gitlab-ci.yml',
                        content: nuget_install_yaml
                    }
                ]
              )
            end
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('install')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.group.visit!

          Page::Group::Menu.perform(&:go_to_group_packages)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)
            index.click_package(package.name)
          end

          Page::Project::Packages::Show.perform(&:click_delete)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_content('Package deleted successfully')
            expect(index).not_to have_package(package.name)
          end
        end
      end
    end
  end
end
