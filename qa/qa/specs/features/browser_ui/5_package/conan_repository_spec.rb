# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages do
    describe 'Conan Repository' do
      include Runtime::Fixtures

      let(:package_name) { 'conantest' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'conan-package-project'
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

      after do
        runner.remove_via_api!
      end

      it 'publishes a conan package and deletes it', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1077' do
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([{
                                file_path: '.gitlab-ci.yml',
                                content:
                                    <<~YAML
                                      image: conanio/gcc7

                                      create_package:
                                        stage: deploy
                                        script:
                                          - "conan remote add gitlab #{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/conan"
                                          - "conan new #{package_name}/0.1 -t"
                                          - "conan create . mycompany/stable"
                                          - "CONAN_LOGIN_USERNAME=ci_user CONAN_PASSWORD=${CI_JOB_TOKEN} conan upload #{package_name}/0.1@mycompany/stable --all --remote=gitlab"
                                        tags:
                                           - "runner-for-#{project.name}"
                                    YAML
                            }])
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('create_package')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package_name)
          index.click_package(package_name)
        end

        Page::Project::Packages::Show.perform do |package|
          package.click_delete
        end

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_content("Package deleted successfully")
          expect(index).to have_no_package(package_name)
        end
      end
    end
  end
end
