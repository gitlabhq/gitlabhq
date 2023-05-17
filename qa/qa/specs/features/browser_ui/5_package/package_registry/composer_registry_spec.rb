# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage, product_group: :package_registry do
    describe 'Composer Repository' do
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'composer-package-project'
          project.visibility = :private
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "my_package-#{SecureRandom.hex(4)}"
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

      let!(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      before do
        Flow::Login.sign_in
        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            composer_yaml = ERB.new(read_fixture('package_managers/composer', 'composer_upload_package.yaml.erb')).result(binding)
            composer_json = ERB.new(read_fixture('package_managers/composer', 'composer.json.erb')).result(binding)

            commit.project = project
            commit.commit_message = 'Add files'
            commit.add_files([{
                                file_path: '.gitlab-ci.yml',
                                content: composer_yaml
                              },
                              {
                                file_path: 'composer.json',
                                content: composer_json
                              }]
                            )
          end
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

      it 'publishes a composer package and deletes it', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348016' do
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
