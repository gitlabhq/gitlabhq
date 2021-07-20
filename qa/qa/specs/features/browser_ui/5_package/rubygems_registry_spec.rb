# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :requires_admin, :packages, :object_storage do
    describe 'RubyGems Repository' do
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'rubygems-package-project'
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = 'mygem'
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

      let(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      before do
        Runtime::Feature.enable(:rubygem_packages, project: project)
      end

      after do
        Runtime::Feature.disable(:rubygem_packages, project: project)
        runner.remove_via_api!
        package.remove_via_api!
        project.remove_via_api!
      end

      it 'publishes and deletes a Ruby gem', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1131' do
        Flow::Login.sign_in

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../fixtures/rubygems_package')
          push.commit_message = 'RubyGems package'
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add mygem.gemspec'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content:
                  <<~YAML
                    image: ruby

                    test_package:
                      stage: deploy
                      before_script:
                        - mkdir ~/.gem
                        - echo "---" > ~/.gem/credentials
                        - |
                          echo "#{gitlab_address_with_port}/api/v4/projects/${CI_PROJECT_ID}/packages/rubygems: '${CI_JOB_TOKEN}'" >> ~/.gem/credentials
                        - chmod 0600 ~/.gem/credentials
                      script:
                        - gem build mygem
                        - gem push mygem-0.0.1.gem --host #{gitlab_address_with_port}/api/v4/projects/${CI_PROJECT_ID}/packages/rubygems
                      tags:
                        - "runner-for-#{project.name}"
                  YAML
              },
              {
                file_path: 'lib/hello_gem.rb',
                content:
                  <<~RUBY
                    class HelloWorld
                      def self.hi
                        puts "Hello world!"
                      end
                    end
                  RUBY
              }
            ]
          )
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('test_package')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
          index.click_package(package.name)
        end

        Page::Project::Packages::Show.perform(&:click_delete)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_content("Package deleted successfully")
          expect(index).not_to have_package(package.name)
        end
      end
    end
  end
end
