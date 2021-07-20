# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :reliable, :object_storage do
    describe 'npm registry' do
      include Runtime::Fixtures

      let!(:registry_scope) { Runtime::Namespace.sandbox_name }
      let(:auth_token) do
        unless Page::Main::Menu.perform(&:signed_in?)
          Flow::Login.sign_in
        end

        Resource::PersonalAccessToken.fabricate!.token
      end

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:gitlab_address_with_port) { "#{uri.scheme}://#{uri.host}:#{uri.port}" }
      let(:gitlab_host_with_port) { "#{uri.host}:#{uri.port}" }

      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'npm-project'
        end
      end

      let!(:another_project) do
        Resource::Project.fabricate_via_api! do |another_project|
          another_project.name = 'npm-another-project'
          another_project.template_name = 'express'
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

      let(:gitlab_ci_deploy_yaml) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
              image: node:14-buster

              stages:
                - deploy

              deploy:
                stage: deploy
                script:
                  - npm publish
                only:
                  - "#{project.default_branch}"
                tags:
                  - "runner-for-#{project.group.name}"
              YAML
        }
      end

      let(:gitlab_ci_install_yaml) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
              image: node:latest

              stages:
                - install

              install:
                stage: install
                script:
                  - "npm config set @#{registry_scope}:registry #{gitlab_address_with_port}/api/v4/packages/npm/"
                  - "npm install #{package.name}"
                cache:
                  key: ${CI_BUILD_REF_NAME}
                  paths:
                    - node_modules/
                artifacts:
                  paths:
                    - node_modules/
                only:
                  - "#{another_project.default_branch}"
                tags:
                  - "runner-for-#{another_project.group.name}"
              YAML
        }
      end

      let(:package_json) do
        {
          file_path: 'package.json',
          content: <<~JSON
            {
              "name": "#{package.name}",
              "version": "1.0.0",
              "description": "Example package for GitLab npm registry",
              "publishConfig": {
                "@#{registry_scope}:registry": "#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/npm/"
              }
            }
          JSON
      }
      end

      let(:npmrc) do
        {
          file_path: '.npmrc',
          content: <<~NPMRC
            //#{gitlab_host_with_port}/api/v4/projects/#{project.id}/packages/npm/:_authToken=#{auth_token}
            @#{registry_scope}:registry=#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/npm/
          NPMRC
        }
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "@#{registry_scope}/#{project.name}"
          package.project = project
        end
      end

      after do
        package.remove_via_api!
        runner.remove_via_api!
        project.remove_via_api!
        another_project.remove_via_api!
      end

      it 'push and pull a npm package via CI', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1772' do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([
                            gitlab_ci_deploy_yaml,
                            npmrc,
                            package_json
                          ])
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('deploy')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = another_project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([
                             gitlab_ci_install_yaml
          ])
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
          expect(artifacts).to have_content( "#{project.name}")
        end

        project.visit!
        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)

          index.click_package(package.name)
        end

        Page::Project::Packages::Show.perform do |show|
          expect(show).to have_package_info(package.name, "1.0.0")

          show.click_delete
        end

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_content("Package deleted successfully")
          expect(index).not_to have_package(package.name)
        end
      end
    end
  end
end
