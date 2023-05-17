# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :requires_admin, :packages, :object_storage, :reliable,
  feature_flag: {
    name: 'maven_central_request_forwarding',
    scope: :global
  } do
    describe 'Maven project level endpoint', product_group: :package_registry do
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven' }
      let(:personal_access_token) { Runtime::Env.personal_access_token }

      let(:package_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "#{package_type}_package_project"
          project.initialize_with_readme = true
          project.visibility = :private
        end
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = package_name
          package.project = package_project
        end
      end

      let(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{package_project.name}"]
          runner.executor = :docker
          runner.project = package_project
        end
      end

      let(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      let(:project_deploy_token) do
        Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'package-deploy-token'
          deploy_token.project = package_project
          deploy_token.scopes = %w[
            read_repository
            read_package_registry
            write_package_registry
          ]
        end
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        runner
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
        package_project.remove_via_api!
      end

      where do
        {
          'using a personal access token' => {
            authentication_token_type: :personal_access_token,
            maven_header_name: 'Private-Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354347'
          },
          'using a project deploy token' => {
            authentication_token_type: :project_deploy_token,
            maven_header_name: 'Deploy-Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354348'
          },
          'using a ci job token' => {
            authentication_token_type: :ci_job_token,
            maven_header_name: 'Job-Token',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354349'
          }
        }
      end

      with_them do
        let(:token) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: package_project)
          when :ci_job_token
            '${CI_JOB_TOKEN}'
          when :project_deploy_token
            use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: package_project)
          end
        end

        it 'pushes and pulls a maven package via maven', testcase: params[:testcase] do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              gitlab_ci_yaml = ERB.new(read_fixture('package_managers/maven/project', 'gitlab_ci.yaml.erb'))
                                        .result(binding)
              pom_xml = ERB.new(read_fixture('package_managers/maven/project', 'pom.xml.erb'))
                                        .result(binding)
              settings_xml = ERB.new(read_fixture('package_managers/maven/project', 'settings.xml.erb'))
                                        .result(binding)

              commit.project = package_project
              commit.commit_message = 'Add files'
              commit.add_files(
                [
                  { file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml },
                  { file_path: 'pom.xml', content: pom_xml },
                  { file_path: 'settings.xml', content: settings_xml }
                ])
            end
          end

          package_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy-and-install')
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
        end
      end
    end

    describe 'Maven request forwarding' do
      include Runtime::Fixtures

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven' }
      let(:personal_access_token) { Runtime::Env.personal_access_token }
      let(:group) { Resource::Group.fabricate_via_api! }

      let(:gitlab_address_with_port) do
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = package_name
          package.project = imported_project
        end
      end

      let(:runner) do
        Resource::GroupRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{imported_project.name}"]
          runner.executor = :docker
          runner.group = group
        end
      end

      let(:imported_project) do
        Resource::ProjectImportedFromURL.fabricate_via_browser_ui! do |project|
          project.name = "#{package_type}_imported_project"
          project.group = group
          project.gitlab_repository_path = 'https://gitlab.com/gitlab-org/quality/imported-projects/maven.git'
        end
      end

      before do
        QA::Support::Helpers::ImportSource.enable('git')

        Runtime::Feature.enable(:maven_central_request_forwarding)
        Flow::Login.sign_in_unless_signed_in

        imported_project
        runner
      end

      after do
        Runtime::Feature.disable(:maven_central_request_forwarding)

        runner.remove_via_api!
        package.remove_via_api!
        imported_project.remove_via_api!
      end

      it(
        'uses GitLab as a mirror of the central proxy',
        :skip_live_env,
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/378221',
          type: :investigating
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/375767'
      ) do
        Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            gitlab_ci_yaml = ERB.new(read_fixture('package_managers/maven/project/request_forwarding',
                                                  'gitlab_ci.yaml.erb'
                                                 )
                                    )
                                    .result(binding)
            settings_xml = ERB.new(read_fixture('package_managers/maven/project/request_forwarding',
                                                'settings.xml.erb'
                                               )
                                  )
                                  .result(binding)

            commit.project = imported_project
            commit.commit_message = 'Add files'
            commit.add_files(
              [
                { file_path: '.gitlab-ci.yml', content: gitlab_ci_yaml },
                { file_path: 'settings.xml', content: settings_xml }
              ])
          end
        end

        imported_project.visit!

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('install')
        end

        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 800)
        end
      end
    end
  end
end
