# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage, product_group: :package_registry, quarantine: {
    only: { job: 'object_storage' },
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/335981',
    type: :bug
  } do
    describe 'Conan Repository' do
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'conan-package-project'
          project.visibility = :private
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "conantest-#{SecureRandom.hex(8)}"
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

      let(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
      end

      it 'publishes, installs, and deletes a Conan package', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348014' do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            conan_yaml = ERB.new(read_fixture('package_managers/conan', 'conan_upload_install_package.yaml.erb')).result(binding)

            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files([{
                                  file_path: '.gitlab-ci.yml',
                                  content: conan_yaml
                              }])
          end
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('test_package')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Page::Project::Menu.perform(&:go_to_package_registry)

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
