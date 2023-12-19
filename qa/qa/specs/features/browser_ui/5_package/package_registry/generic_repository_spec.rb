# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, product_group: :package_registry do
    describe 'Generic Repository', :external_api_calls do
      include Runtime::Fixtures

      let(:project) { create(:project, :private, name: 'generic-package-project') }
      let(:package) { build(:package, name: "my_package-#{SecureRandom.hex(8)}", project: project) }

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{Time.now.to_i}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:file_txt) do
        <<~EOF
          Hello, world!
        EOF
      end

      before do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          generic_packages_yaml = ERB.new(read_fixture('package_managers/generic', 'generic_upload_install_package.yaml.erb')).result(binding)

          create(:commit, project: project, commit_message: 'Add files', actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: generic_packages_yaml },
            { action: 'create', file_path: 'file.txt', content: file_txt }
          ])
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('upload')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)

          job.go_to_pipeline
        end

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('download')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)
        end
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
      end

      it 'uploads a generic package and downloads it', :reliable,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348017' do
        Page::Project::Menu.perform(&:go_to_package_registry)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
        end
      end
    end
  end
end
