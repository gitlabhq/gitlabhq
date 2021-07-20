# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'PyPI Repository' do
      include Runtime::Fixtures
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pypi-package-project'
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = 'mypypipackage'
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
        Flow::Login.sign_in

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files([{
                                file_path: '.gitlab-ci.yml',
                                content:
                                    <<~YAML
                                      image: python:latest

                                      run:
                                        script:
                                          - pip install twine
                                          - python setup.py sdist bdist_wheel
                                          - "TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token python -m twine upload --repository-url #{gitlab_address_with_port}/api/v4/projects/${CI_PROJECT_ID}/packages/pypi dist/*"
                                        tags:
                                          - "runner-for-#{project.name}"
                                    YAML
                            },
                            {
                                file_path: 'setup.py',
                                content:
                                    <<~EOF
                                      import setuptools

                                      setuptools.setup(
                                          name="mypypipackage",
                                          version="0.0.1",
                                          author="Example Author",
                                          author_email="author@example.com",
                                          description="A small example package",
                                          packages=setuptools.find_packages(),
                                          classifiers=[
                                              "Programming Language :: Python :: 3",
                                              "License :: OSI Approved :: MIT License",
                                              "Operating System :: OS Independent",
                                          ],
                                          python_requires='>=3.6',
                                      )
                                    EOF

                            }])
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('run')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
        project&.remove_via_api!
      end

      it 'publishes a pypi package and deletes it', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1087' do
        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
          index.click_package(package.name)
        end

        Page::Project::Packages::Show.perform(&:click_delete)

        Page::Project::Packages::Index.perform do |index|
          aggregate_failures do
            expect(index).to have_content("Package deleted successfully")
            expect(index).not_to have_package(package.name)
          end
        end
      end

      context 'Geo', :orchestrated, :geo do
        it 'replicates a published pypi package to the Geo secondary site', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1120', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/325556', type: :investigating } do
          QA::Runtime::Logger.debug('Visiting the secondary Geo site')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            Page::Project::Menu.perform(&:click_packages_link)

            Page::Project::Packages::Index.perform do |index|
              index.wait_for_package_replication(package.name)
              expect(index).to have_package(package.name)
            end
          end
        end
      end
    end
  end
end
