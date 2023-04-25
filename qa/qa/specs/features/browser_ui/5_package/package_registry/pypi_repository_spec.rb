# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :skip_live_env, :orchestrated, :packages, :object_storage, product_group: :package_registry do
    describe 'PyPI Repository' do
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pypi-package-project'
          project.visibility = :private
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "mypypipackage-#{SecureRandom.hex(8)}"
          package.project = project
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:personal_access_token) { use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: Runtime::Env.personal_access_token, project: project) }
      let(:gitlab_address_with_port) { "#{uri.scheme}://#{uri.host}:#{uri.port}" }
      let(:gitlab_host_with_port) do
        # Don't specify port if it is a standard one
        if uri.port == 80 || uri.port == 443
          uri.host
        else
          "#{uri.host}:#{uri.port}"
        end
      end

      before do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            pypi_yaml = ERB.new(read_fixture('package_managers/pypi', 'pypi_upload_install_package.yaml.erb')).result(binding)
            pypi_setup_file = ERB.new(read_fixture('package_managers/pypi', 'setup.py.erb')).result(binding)

            commit.project = project
            commit.commit_message = 'Add files'
            commit.add_files([{
                                  file_path: '.gitlab-ci.yml',
                                  content: pypi_yaml
                              },
                              {
                                  file_path: 'setup.py',
                                  content: pypi_setup_file
                              }])
          end
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('run')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('install')
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

      context 'when at the project level' do
        it 'publishes and installs a pypi package', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348015' do
          Page::Project::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)
          end
        end
      end

      context 'Geo', :orchestrated, :geo do
        it 'replicates a published pypi package to the Geo secondary site', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348090', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/325556', type: :investigating } do
          QA::Runtime::Logger.debug('Visiting the secondary Geo site')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            Page::Project::Menu.perform(&:go_to_package_registry)

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
