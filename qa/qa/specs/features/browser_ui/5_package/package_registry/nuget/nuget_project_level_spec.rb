# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'NuGet project level endpoint' do
      using RSpec::Parameterized::TableSyntax
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

      let(:project_deploy_token) do
        Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'package-deploy-token'
          deploy_token.project = project
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

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
        project.remove_via_api!
      end

      where(:authentication_token_type, :token_name) do
        :personal_access_token | 'Personal Access Token'
        :ci_job_token          | 'CI Job Token'
        :project_deploy_token  | 'Deploy Token'
      end

      with_them do
        let(:auth_token_password) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token.token}\""
          when :ci_job_token
            '${CI_JOB_TOKEN}'
          when :project_deploy_token
            "\"#{project_deploy_token.token}\""
          end
        end

        let(:auth_token_username) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token.user.username}\""
          when :ci_job_token
            'gitlab-ci-token'
          when :project_deploy_token
            "\"#{project_deploy_token.username}\""
          end
        end

        it "publishes a nuget package and installs using a #{params[:token_name]}" do
          Flow::Login.sign_in

          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = project
              commit.commit_message = 'Add files'
              commit.update_files(
                [
                    {
                        file_path: '.gitlab-ci.yml',
                        content: <<~YAML
                          deploy-and-install:
                            image: mcr.microsoft.com/dotnet/sdk:5.0
                            script:
                              - dotnet restore -p:Configuration=Release
                              - dotnet build -c Release
                              - dotnet pack -c Release -p:PackageID=#{package.name}
                              - dotnet nuget add source "$CI_SERVER_URL/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" --name gitlab --username #{auth_token_username} --password #{auth_token_password} --store-password-in-clear-text
                              - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
                              - "dotnet add dotnetcore.csproj package #{package.name} --version 1.0.0"
                            rules:
                              - if: '$CI_COMMIT_BRANCH == "#{project.default_branch}"'
                            tags:
                              - "runner-for-#{project.name}"
                        YAML
                    },
                    {
                      file_path: 'dotnetcore.csproj',
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
            end
          end

          project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy-and-install')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Page::Project::Menu.perform(&:click_packages_link)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)
          end
        end
      end
    end
  end
end
