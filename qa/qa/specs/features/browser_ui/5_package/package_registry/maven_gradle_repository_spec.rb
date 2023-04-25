# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :skip_live_env, :orchestrated, :packages, :object_storage, product_group: :package_registry do
    describe 'Maven Repository with Gradle' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include_context 'packages registry qa scenario'

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven_gradle-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven_gradle' }

      where(:case_name, :authentication_token_type, :maven_header_name, :testcase) do
        'using personal access token' | :personal_access_token | 'Private-Token' | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347601'
        'using ci job token'          | :ci_job_token          | 'Job-Token'     | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347603'
        'using project deploy token'  | :project_deploy_token  | 'Deploy-Token'  | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347602'
      end

      with_them do
        let(:token) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token}\""
          when :ci_job_token
            package_project_inbound_job_token_disabled
            client_project_inbound_job_token_disabled
            'System.getenv("CI_JOB_TOKEN")'
          when :project_deploy_token
            "\"#{project_deploy_token.token}\""
          end
        end

        it 'pushes and pulls a maven package via gradle', testcase: params[:testcase] do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              gradle_upload_yaml = ERB.new(read_fixture('package_managers/maven/gradle', 'gradle_upload_package.yaml.erb')).result(binding)
              build_upload_gradle = ERB.new(read_fixture('package_managers/maven/gradle', 'build_upload.gradle.erb')).result(binding)

              commit.project = package_project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files(
                [
                  { file_path: '.gitlab-ci.yml', content: gradle_upload_yaml },
                  { file_path: 'build.gradle', content: build_upload_gradle }
                ])
            end
          end

          package_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Page::Project::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package_name)

            index.click_package(package_name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package_name, package_version)
          end

          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              gradle_install_yaml = ERB.new(read_fixture('package_managers/maven/gradle', 'gradle_install_package.yaml.erb')).result(binding)
              build_install_gradle = ERB.new(read_fixture('package_managers/maven/gradle', 'build_install.gradle.erb')).result(binding)

              commit.project = client_project
              commit.commit_message = 'Add files'
              commit.add_files(
                [
                  { file_path: '.gitlab-ci.yml', content: gradle_install_yaml },
                  { file_path: 'build.gradle', content: build_install_gradle }
                ])
            end
          end

          client_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('build')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end
        end
      end
    end
  end
end
