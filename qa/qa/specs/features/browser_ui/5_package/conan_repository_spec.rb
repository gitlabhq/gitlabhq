# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage, quarantine: {
    only: { job: 'object_storage' },
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/335981',
    type: :bug
  } do
    describe 'Conan Repository' do
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'conan-package-project'
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = 'conantest'
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

      after do
        runner.remove_via_api!
        package.remove_via_api!
      end

      it 'publishes, installs, and deletes a Conan package', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1077' do
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([{
                                file_path: '.gitlab-ci.yml',
                                content:
                                    <<~YAML
                                      image: conanio/gcc7

                                      test_package:
                                        stage: deploy
                                        script:
                                          - "conan remote add gitlab #{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/conan"
                                          - "conan new #{package.name}/0.1 -t"
                                          - "conan create . mycompany/stable"
                                          - "CONAN_LOGIN_USERNAME=ci_user CONAN_PASSWORD=${CI_JOB_TOKEN} conan upload #{package.name}/0.1@mycompany/stable --all --remote=gitlab"
                                          - "conan install #{package.name}/0.1@mycompany/stable --remote=gitlab"
                                        tags:
                                           - "runner-for-#{project.name}"
                                    YAML
                            }])
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
