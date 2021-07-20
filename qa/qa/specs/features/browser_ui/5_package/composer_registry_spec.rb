# frozen_string_literal: true

require 'securerandom'

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'Composer Repository' do
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'composer-package-project'
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "my_package-#{SecureRandom.hex(4)}"
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

      let!(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      let(:composer_json_file) do
        <<~EOF
          {
            "name": "#{project.path_with_namespace}/#{package.name}",
            "description": "Library XY",
            "type": "library",
            "license": "GPL-3.0-only",
            "authors": [
               {
                   "name": "John Doe",
                   "email": "john@example.com"
               }
            ],
            "require": {}
          }
        EOF
      end

      let(:gitlab_ci_yaml) do
        <<~YAML
          publish:
            image: curlimages/curl:latest
            stage: build
            variables:
              URL: "$CI_SERVER_PROTOCOL://$CI_SERVER_HOST:$CI_SERVER_PORT/api/v4/projects/$CI_PROJECT_ID/packages/composer?job_token=$CI_JOB_TOKEN"
            script:
              - version=$([[ -z "$CI_COMMIT_TAG" ]] && echo "branch=$CI_COMMIT_REF_NAME" || echo "tag=$CI_COMMIT_TAG")
              - insecure=$([ "$CI_SERVER_PROTOCOL" = "http" ] && echo "--insecure" || echo "")
              - response=$(curl -s -w "%{http_code}" $insecure --data $version $URL)
              - code=$(echo "$response" | tail -n 1)
              - body=$(echo "$response" | head -n 1)
            tags:
              - "runner-for-#{project.name}"
        YAML
      end

      before do
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([{
                              file_path: '.gitlab-ci.yml',
                              content: gitlab_ci_yaml
                            },
                            {
                              file_path: 'composer.json',
                              content: composer_json_file
                            }]
                          )
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('publish')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
      end

      it 'publishes a composer package and deletes it', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1088' do
        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
          index.click_package(package.name)
        end

        Page::Project::Packages::Show.perform(&:click_delete)

        Page::Project::Packages::Index.perform do |index|
          aggregate_failures 'package deletion' do
            expect(index).to have_content("Package deleted successfully")
            expect(index).not_to have_package(package.name)
          end
        end
      end
    end
  end
end
