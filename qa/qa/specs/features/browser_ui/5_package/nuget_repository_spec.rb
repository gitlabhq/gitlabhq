# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages do
    describe 'NuGet Repository' do
      include Runtime::Fixtures

      let(:package_name) { 'dotnetcore' }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'nuget-package-project'
          project.template_name = 'dotnetcore'
        end
      end

      let(:another_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'nuget-package-install-project'
          project.template_name = 'dotnetcore'
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

      let!(:another_runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{another_project.name}"]
          runner.executor = :docker
          runner.project = another_project
        end
      end

      after do
        runner.remove_via_api!
        another_runner.remove_via_api!
      end

      it 'publishes a nuget package at the project level, installs and deletes it at the group level', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1073' do
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.update_files(
            [
                {
                    file_path: '.gitlab-ci.yml',
                    content: <<~YAML
                      image: mcr.microsoft.com/dotnet/core/sdk:3.1

                      stages:
                        - deploy

                      deploy:
                        stage: deploy
                        script:
                          - dotnet restore -p:Configuration=Release
                          - dotnet build -c Release
                          - dotnet pack -c Release
                          - dotnet nuget add source "$CI_SERVER_URL/api/v4/projects/$CI_PROJECT_ID/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
                          - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
                        only:
                          - "#{project.default_branch}"
                        tags:
                          - "runner-for-#{project.name}"
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
                            <TargetFramework>netcoreapp3.1</TargetFramework>
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
                        image: mcr.microsoft.com/dotnet/core/sdk:3.1

                        stages:
                          - install

                        install:
                          stage: install
                          script:
                           - dotnet nuget locals all --clear
                           - dotnet nuget add source "$CI_SERVER_URL/api/v4/groups/#{another_project.group.id}/-/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
                           - "dotnet add otherdotnet.csproj package #{package_name} --version 1.0.0"
                          only:
                            - "#{another_project.default_branch}"
                          tags:
                            - "runner-for-#{another_project.name}"
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

        project.group.sandbox.visit!

        Page::Group::Menu.perform(&:go_to_group_packages)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package_name)
          index.click_package(package_name)
        end

        Page::Project::Packages::Show.perform do |package|
          package.click_delete
        end

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_content("Package deleted successfully")
          expect(index).not_to have_package(package_name)
        end
      end
    end
  end
end
