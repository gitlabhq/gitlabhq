# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, :skip_fips_env, :external_api_calls, product_group: :package_registry,
    quarantine: {
      only: {
        job: /object_storage|cng-instance|release-environments-qa|qa_gke.*|qa_eks.*|debug_review_gke125/,
        condition: -> { QA::Support::FIPS.enabled? }
      },
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/417584',
      type: :bug
    } do
    describe 'Conan Repository' do
      include Runtime::Fixtures

      let(:project) { create(:project, :private, name: 'conan-package-project') }
      let(:package) { build(:package, name: "conantest-#{SecureRandom.hex(8)}", project: project) }

      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{SecureRandom.hex(6)}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:gitlab_address_with_port) do
        Support::GitlabAddress.address_with_port
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      it 'publishes, installs, and deletes a Conan package',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348014' do
        conan_yaml = ERB.new(read_fixture('package_managers/conan',
          'conan_upload_install_package.yaml.erb')).result(binding)

        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          { action: 'create', file_path: '.gitlab-ci.yml', content: conan_yaml }
        ])

        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)

        project.visit_job('test_package')
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)
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
