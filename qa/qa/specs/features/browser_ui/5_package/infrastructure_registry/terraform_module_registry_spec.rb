# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :requires_admin, product_group: :package_registry do
    describe 'Terraform Module Registry',
      quarantine: {
        only: { job: 'airgapped' },
        issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/417407',
        type: :investigating
      } do
      include Runtime::Fixtures

      let(:group) { create(:group) }

      let(:imported_project) do
        Resource::ProjectImportedFromURL.fabricate_via_browser_ui! do |project|
          project.name = 'terraform-module-test'
          project.group = group
          project.gitlab_repository_path = 'https://gitlab.com/mattkasa/terraform-module-test.git'
        end.reload!
      end

      let(:runner) do
        Resource::Ci::ProjectRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{SecureRandom.hex(6)}"
          runner.tags = ["runner-for-#{imported_project.name}"]
          runner.executor = :docker
          runner.project = imported_project
        end
      end

      before do
        # Remove 'requires_admin' if below method is removed
        QA::Support::Helpers::ImportSource.enable('git')

        Flow::Login.sign_in
        imported_project
        runner
      end

      after do
        runner.remove_via_api!
      end

      it 'publishes a module',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/371583' do
        terraform_module_yaml = ERB.new(
          read_fixture('package_managers/terraform', 'module_upload.yaml.erb')
        ).result(binding)

        create(:commit, project: imported_project, commit_message: 'Add gitlab-ci.yaml file', actions: [
          { action: 'update', file_path: '.gitlab-ci.yml', content: terraform_module_yaml }
        ])

        create(:tag, project: imported_project, ref: imported_project.default_branch, name: '1.0.0')

        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: imported_project)
        imported_project.visit_job('upload')
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)
        end

        Page::Project::Menu.perform(&:go_to_infrastructure_registry)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_module("#{imported_project.name}/local")
        end
      end
    end
  end
end
