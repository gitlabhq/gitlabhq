# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, product_group: :package_registry do
    describe 'Generic Repository', :external_api_calls do
      include Runtime::Fixtures

      let(:project) { create(:project, :private, name: 'generic-package-project') }
      let(:package) { build(:package, name: "my_package-#{SecureRandom.hex(8)}", project: project) }

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{SecureRandom.hex(6)}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:file_txt) do
        <<~CONTENT
          Hello, world!
        CONTENT
      end

      before do
        generic_packages_yaml = ERB.new(read_fixture('package_managers/generic',
          'generic_upload_install_package.yaml.erb')).result(binding)

        create(:commit, project: project, commit_message: 'Add files', actions: [
          { action: 'create', file_path: '.gitlab-ci.yml', content: generic_packages_yaml },
          { action: 'create', file_path: 'file.txt', content: file_txt }
        ])

        Flow::Login.sign_in
        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
      end

      after do
        runner.remove_via_api!
      end

      it 'uploads a generic package and downloads it',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348017' do
        project.visit_job('upload')
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)
        end

        project.visit_job('download')
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)
        end

        Page::Project::Menu.perform(&:go_to_package_registry)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
        end
      end
    end
  end
end
