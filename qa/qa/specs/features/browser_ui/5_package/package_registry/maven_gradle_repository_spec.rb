# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, :external_api_calls,
    quarantine: {
      only: { condition: -> { QA::Support::FIPS.enabled? } },
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/417600',
      type: :investigating
    }, product_group: :package_registry do
    describe 'Maven Repository with Gradle' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:personal_access_token) { Runtime::User::Store.default_api_client.personal_access_token }
      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven_gradle-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven_gradle' }
      let(:project) { create(:project, :private, :with_readme, name: "#{package_type}_project") }
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

      let(:project_deploy_token) do
        create(:project_deploy_token,
          name: 'package-deploy-token',
          project: project,
          scopes: %w[
            read_repository
            read_package_registry
            write_package_registry
          ])
      end

      let(:project_inbound_job_token_disabled) do
        Resource::CICDSettings.fabricate_via_api! do |settings|
          settings.project_path = project.full_path
          settings.inbound_job_token_scope_enabled = false
        end
      end

      before do
        Flow::Login.sign_in_unless_signed_in
      end

      where(:case_name, :authentication_token_type, :maven_header_name, :testcase) do
        'using personal access token' | :personal_access_token | 'Private-Token' | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347601'
        'using ci job token'          | :ci_job_token          | 'Job-Token'     | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347603'
        'using project deploy token'  | :project_deploy_token  | 'Deploy-Token'  | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347602'
      end

      with_them do
        let(:token) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: project)
          when :ci_job_token
            project_inbound_job_token_disabled
            '${CI_JOB_TOKEN}'
          when :project_deploy_token
            use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: project)
          end
        end

        it 'pushes and pulls a maven package via gradle', testcase: params[:testcase] do
          gradle_publish_install_yaml = ERB.new(read_fixture('package_managers/maven/gradle',
            'gradle_upload_install_package.yaml.erb')).result(binding)
          build_gradle = ERB.new(read_fixture('package_managers/maven/gradle', 'build.gradle.erb')).result(binding)

          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: gradle_publish_install_yaml },
            { action: 'create', file_path: 'build.gradle', content: build_gradle }
          ])

          project.visit!
          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)

          project.visit_job('publish')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.visit_job('install')
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
  end
end
