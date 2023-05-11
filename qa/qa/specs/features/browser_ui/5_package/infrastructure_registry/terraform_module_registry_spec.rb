# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :requires_admin, :orchestrated, :packages, product_group: :package_registry do
    describe 'Terraform Module Registry' do
      include Runtime::Fixtures

      let(:group) { Resource::Group.fabricate_via_api! }

      let(:imported_project) do
        Resource::ProjectImportedFromURL.fabricate_via_browser_ui! do |project|
          project.name = 'terraform-module-test'
          project.group = group
          project.gitlab_repository_path = 'https://gitlab.com/mattkasa/terraform-module-test.git'
        end
      end

      let(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{imported_project.name}"]
          runner.executor = :docker
          runner.project = imported_project
        end
      end

      before do
        QA::Support::Helpers::ImportSource.enable('git')

        Flow::Login.sign_in

        imported_project
        runner
      end

      after do
        runner.remove_via_api!
      end

      it 'publishes a module', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/371583' do
        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            terraform_module_yaml = ERB.new(
              read_fixture('package_managers/terraform', 'module_upload.yaml.erb')
            ).result(binding)
            commit.project = imported_project
            commit.commit_message = 'Add gitlab-ci.yaml file'
            commit.update_files([
                                  {
                                    file_path: '.gitlab-ci.yml',
                                    content: terraform_module_yaml
                                  }
                                ]
                               )
          end
        end

        Resource::Tag.fabricate_via_api! do |tag|
          tag.project = imported_project
          tag.ref = imported_project.default_branch
          tag.name = "1.0.0"
        end

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('upload')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end

        Page::Project::Menu.perform(&:go_to_infrastructure_registry)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_module("#{imported_project.name}/local")
        end
      end
    end
  end
end
