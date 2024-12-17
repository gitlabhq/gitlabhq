# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, product_group: :package_registry do
    describe 'Composer Repository', :external_api_calls do
      include Runtime::Fixtures

      let(:project) { create(:project, :private, name: 'composer-package-project') }
      let(:package) { build(:package, name: "my_package-#{SecureRandom.hex(4)}", project: project) }

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{SecureRandom.hex(6)}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:gitlab_address_without_port) { Support::GitlabAddress.address_with_port(with_default_port: false) }

      before do
        Flow::Login.sign_in
        composer_yaml = ERB.new(read_fixture('package_managers/composer',
          'composer_upload_package.yaml.erb')).result(binding)
        composer_json = ERB.new(read_fixture('package_managers/composer', 'composer.json.erb')).result(binding)

        create(:commit, project: project, commit_message: 'Add files', actions: [
          { action: 'create', file_path: '.gitlab-ci.yml', content: composer_yaml },
          { action: 'create', file_path: 'composer.json', content: composer_json }
        ])

        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
      end

      after do
        runner.remove_via_api!
      end

      it(
        'publishes a composer package and deletes it',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348016'
      ) do
        project.visit_job('publish')
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
