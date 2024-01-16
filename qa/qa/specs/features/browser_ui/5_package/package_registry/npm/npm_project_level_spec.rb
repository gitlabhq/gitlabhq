# frozen_string_literal: true

module QA
  RSpec.describe 'Package' do
    describe 'npm Registry project level endpoint', :object_storage, :external_api_calls,
      product_group: :package_registry do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let!(:registry_scope) { Runtime::Namespace.sandbox_name }
      let!(:personal_access_token) do
        Flow::Login.sign_in unless Page::Main::Menu.perform(&:signed_in?)

        Resource::PersonalAccessToken.fabricate!.token
      end

      let(:project_deploy_token) do
        create(:project_deploy_token,
          name: 'npm-deploy-token',
          project: project,
          scopes: %w[
            read_repository
            read_package_registry
            write_package_registry
          ])
      end

      let(:gitlab_address_without_port) { Support::GitlabAddress.address_with_port(with_default_port: false) }
      let(:gitlab_host_without_port) { Support::GitlabAddress.host_with_port(with_default_port: false) }
      let!(:project) { create(:project, :private, name: 'npm-project-level') }
      let!(:runner) do
        create(:project_runner,
          name: "qa-runner-#{Time.now.to_i}",
          tags: ["runner-for-#{project.name}"],
          executor: :docker,
          project: project)
      end

      let(:package) { build(:package, name: "@#{registry_scope}/mypackage-#{SecureRandom.hex(8)}", project: project) }

      after do
        package.remove_via_api!
        runner.remove_via_api!
        project.remove_via_api!
      end

      where(:case_name, :authentication_token_type, :token_name, :testcase) do
        'using personal access token' | :personal_access_token | 'Personal Access Token' | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347592'
        'using ci job token'          | :ci_job_token          | 'CI Job Token'          | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347594'
        'using project deploy token'  | :project_deploy_token  | 'Deploy Token'          | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347593'
      end

      with_them do
        let(:auth_token) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: project)
          when :ci_job_token
            '${CI_JOB_TOKEN}'
          when :project_deploy_token
            use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: project)
          end
        end

        it 'push and pull a npm package via CI', :reliable, testcase: params[:testcase] do
          npm_upload_install_yaml = ERB.new(read_fixture('package_managers/npm', 'npm_upload_install_package_project.yaml.erb')).result(binding)
          package_json = ERB.new(read_fixture('package_managers/npm', 'package.json.erb')).result(binding)

          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: npm_upload_install_yaml },
            { action: 'create', file_path: 'package.json', content: package_json }
          ])

          project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('install')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 180)
            job.click_browse_button
          end

          Page::Project::Artifact::Show.perform do |artifacts|
            artifacts.go_to_directory('node_modules')
            artifacts.go_to_directory("@#{registry_scope}")
            expect(artifacts).to have_content('mypackage')
          end

          project.visit!
          Page::Project::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)

            index.click_package(package.name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package.name, "1.0.0")
          end
        end
      end
    end
  end
end
