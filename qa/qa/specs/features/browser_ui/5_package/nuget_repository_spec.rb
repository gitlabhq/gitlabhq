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
        end
      end

      let(:personal_access_token) do
        unless Page::Main::Menu.perform(&:signed_in?)
          Flow::Login.sign_in
        end

        Resource::PersonalAccessToken.fabricate!
      end

      let(:group_deploy_token) do
        Resource::GroupDeployToken.fabricate_via_browser_ui! do |deploy_token|
          deploy_token.name = 'nuget-group-deploy-token'
          deploy_token.group = project.group
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
          runner.token = project.group.runners_token
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
            "\"#{group_deploy_token.password}\""
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

          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.update_files(
              [
                  {
                      file_path: '.gitlab-ci.yml',
                      content: <<~YAML
                        image: mcr.microsoft.com/dotnet/sdk:5.0

                        stages:
                          - deploy

                        deploy:
                          stage: deploy
                          script:
                            - dotnet restore -p:Configuration=Release
                            - dotnet build -c Release
                            - dotnet pack -c Release -p:PackageID=#{package.name}
                            - dotnet nuget add source "$CI_SERVER_URL/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" --name gitlab --username #{auth_token_username} --password #{auth_token_password} --store-password-in-clear-text
                            - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
                          rules:
                            - if: '$CI_COMMIT_BRANCH == "#{project.default_branch}"'
                          tags:
                            - "runner-for-#{project.group.name}"
                      YAML
                  }
              ]
            )
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

          Resource::Repository::Commit.fabricate_via_api! do |commit|
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
                      content: <<~YAML
                          image: mcr.microsoft.com/dotnet/sdk:5.0

                          stages:
                            - install

                          install:
                            stage: install
                            script:
                            - dotnet nuget locals all --clear
                            - dotnet nuget add source "$CI_SERVER_URL/api/v4/groups/#{another_project.group.id}/-/packages/nuget/index.json" --name gitlab --username #{auth_token_username} --password #{auth_token_password} --store-password-in-clear-text
                            - "dotnet add otherdotnet.csproj package #{package.name} --version 1.0.0"
                            only:
                              - "#{another_project.default_branch}"
                            tags:
                              - "runner-for-#{project.group.name}"
                      YAML
                  }
              ]
            )
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
