# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages do
    describe 'PyPI Repository' do
      include Runtime::Fixtures

      let(:package_name) { 'mypypipackage' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pypi-package-project'
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
      end

      it 'publishes a pypi package and deletes it', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1087' do
        Page::Project::Menu.perform(&:click_packages_link)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package_name)
          index.click_package(package_name)
        end

        Page::Project::Packages::Show.perform do |package|
          package.click_delete
        end

        Page::Project::Packages::Index.perform do |index|
          aggregate_failures do
            expect(index).to have_content("Package deleted successfully")
            expect(index).to have_no_package(package_name)
          end
        end
      end
    end
  end
end
