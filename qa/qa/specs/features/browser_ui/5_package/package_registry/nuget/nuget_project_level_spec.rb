# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, product_group: :package_registry, quarantine: {
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/455027',
    only: { condition: -> { ENV['QA_RUN_TYPE']&.match?('gdk-instance') } },
    type: :investigating
  } do
    describe 'NuGet project level endpoint', :external_api_calls do
      include Support::Helpers::MaskToken

      let(:project) { create(:project, :private, name: 'nuget-package-project', template_name: 'dotnetcore') }
      let(:personal_access_token) { Resource::PersonalAccessToken.fabricate_via_api!.token }
      let(:project_deploy_token) do
        create(:project_deploy_token,
          name: 'package-deploy-token',
          project: project,
          scopes: %w[
            read_repository
            read_package_registry
            write_package_registry
          ])
      end

      let(:package) { build(:package, name: "dotnetcore-#{SecureRandom.hex(8)}", project: project) }

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{SecureRandom.hex(6)}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      where do
        {
          'using a personal access token' => {
            authentication_token_type: :personal_access_token,
            maven_header_name: 'Private-Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354351'
          },
          'using a project deploy token' => {
            authentication_token_type: :project_deploy_token,
            maven_header_name: 'Deploy-Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354352'
          },
          'using a ci job token' => {
            authentication_token_type: :ci_job_token,
            maven_header_name: 'Job-Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354353'
          }
        }
      end

      with_them do
        let(:auth_token_password) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token.token, project: project)
          when :ci_job_token
            '${CI_JOB_TOKEN}'
          when :project_deploy_token
            use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: project)
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

        it 'publishes a nuget package and installs', testcase: params[:testcase] do
          create(:commit, project: project, actions: [
            {
              action: 'update',
              file_path: '.gitlab-ci.yml',
              content: <<~YAML
                  stages:
                    - deploy
                    - install

                  deploy:
                    stage: deploy
                    image: mcr.microsoft.com/dotnet/sdk:5.0
                    script:
                      - dotnet restore -p:Configuration=Release
                      - dotnet build -c Release
                      - dotnet pack -c Release -p:PackageID=#{package.name}
                      - dotnet nuget add source "$CI_SERVER_URL/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" --name gitlab --username #{auth_token_username} --password #{auth_token_password} --store-password-in-clear-text
                      - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
                    rules:
                      - if: '$CI_COMMIT_BRANCH == "#{project.default_branch}"'
                    tags:
                      - "runner-for-#{project.name}"

                  install:
                    stage: install
                    image: mcr.microsoft.com/dotnet/sdk:5.0
                    script:
                      - dotnet nuget add source "$CI_SERVER_URL/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" --name gitlab --username #{auth_token_username} --password #{auth_token_password} --store-password-in-clear-text
                      - "dotnet add dotnetcore.csproj package #{package.name} --version 1.0.0"
                    rules:
                      - if: '$CI_COMMIT_BRANCH == "#{project.default_branch}"'
                    tags:
                      - "runner-for-#{project.name}"
              YAML
            },
            {
              action: 'update',
              file_path: 'dotnetcore.csproj',
              content: <<~XML
                  <Project Sdk="Microsoft.NET.Sdk">
                    <PropertyGroup>
                      <OutputType>Exe</OutputType>
                      <TargetFramework>net5.0</TargetFramework>
                    </PropertyGroup>
                  </Project>
              XML
            }
          ])

          project.visit!
          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project, size: 2)

          project.visit_job('deploy')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.visit_job('install')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Page::Project::Menu.perform(&:go_to_package_registry)
          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)
          end
        end
      end
    end
  end
end
