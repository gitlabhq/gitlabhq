# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage, :reliable, product_group: :package_registry do
    describe 'Generic Repository' do
      include Runtime::Fixtures

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'generic-package-project'
          project.visibility = :private
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "my_package-#{SecureRandom.hex(8)}"
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

      let(:file_txt) do
        <<~EOF
          Hello, world!
        EOF
      end

      before do
        Flow::Login.sign_in

        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            generic_packages_yaml = ERB.new(read_fixture('package_managers/generic', 'generic_upload_install_package.yaml.erb')).result(binding)

            commit.project = project
            commit.commit_message = 'Add files'
            commit.add_files([{
                                  file_path: '.gitlab-ci.yml',
                                  content: generic_packages_yaml
                              },
                              {
                                  file_path: 'file.txt',
                                  content: file_txt
                              }]
                            )
          end
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('upload')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)

          job.click_element(:pipeline_path)
        end

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('download')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
      end

      it 'uploads a generic package and downloads it', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348017' do
        Page::Project::Menu.perform(&:go_to_package_registry)

        Page::Project::Packages::Index.perform do |index|
          expect(index).to have_package(package.name)
        end
      end
    end
  end
end
