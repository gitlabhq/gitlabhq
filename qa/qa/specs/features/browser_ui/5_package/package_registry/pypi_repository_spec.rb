# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, product_group: :package_registry do
    describe 'PyPI Repository', :external_api_calls do
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:project) { create(:project, :private, name: 'pypi-package-project') }
      let(:package) { build(:package, name: "mypypipackage-#{SecureRandom.hex(8)}", project: project) }

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{Time.now.to_i}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }

      let!(:personal_access_token) do
        use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: Runtime::Env.personal_access_token, project: project)
      end

      let(:gitlab_address_with_port) { Support::GitlabAddress.address_with_port }
      let(:gitlab_host_with_port) { Support::GitlabAddress.host_with_port(with_default_port: false) }

      before do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          pypi_yaml = ERB.new(read_fixture('package_managers/pypi', 'pypi_upload_install_package.yaml.erb')).result(binding)
          pypi_setup_file = ERB.new(read_fixture('package_managers/pypi', 'setup.py.erb')).result(binding)

          create(:commit, project: project, actions: [
            {
              action: 'create',
              file_path: '.gitlab-ci.yml',
              content: pypi_yaml
            },
            {
              action: 'create',
              file_path: 'setup.py',
              content: pypi_setup_file
            }
          ])
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
        it 'publishes and installs a pypi package', :blocking, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348015' do
          Page::Project::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)
          end
        end
      end

      context 'Geo', :orchestrated, :geo do
        it 'a published pypi package is accessible on a secondary Geo site', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348090', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/325556', type: :investigating } do
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
