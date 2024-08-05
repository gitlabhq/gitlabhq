# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, product_group: :package_registry, quarantine: {
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/455304',
    only: { condition: -> { ENV['QA_RUN_TYPE']&.match?('gdk-qa-blocking') } },
    type: :investigating
  } do
    describe 'NuGet group level endpoint', :external_api_calls do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:project) { create(:project, :private, name: 'nuget-package-project', template_name: 'dotnetcore') }
      let(:personal_access_token) do
        unless Page::Main::Menu.perform(&:signed_in?)
          Flow::Login.sign_in
        end

        Resource::PersonalAccessToken.fabricate!
      end

      let(:group_deploy_token) do
        create(:group_deploy_token,
          name: 'nuget-group-deploy-token',
          group: project.group,
          scopes: %w[
            read_repository
            read_package_registry
            write_package_registry
          ])
      end

      let(:package) { build(:package, name: "dotnetcore-#{SecureRandom.hex(8)}", project: project) }

      let(:another_project) { create(:project, name: 'nuget-package-install-project', template_name: 'dotnetcore', group: project.group) }
      let(:package_project_inbound_job_token_disabled) do
        Resource::CICDSettings.fabricate_via_api! do |settings|
          settings.project_path = project.full_path
          settings.inbound_job_token_scope_enabled = false
        end
      end

      let(:client_project_inbound_job_token_disabled) do
        Resource::CICDSettings.fabricate_via_api! do |settings|
          settings.project_path = another_project.full_path
          settings.inbound_job_token_scope_enabled = false
        end
      end

      let!(:runner) do
        create(:group_runner,
          name: "qa-runner-#{Time.now.to_i}",
          tags: ["runner-for-#{project.group.name}"],
          executor: :docker,
          group: project.group)
      end

      after do
        runner.remove_via_api!
        package.remove_via_api!
        project.remove_via_api!
        another_project.remove_via_api!
      end

      where(:case_name, :authentication_token_type, :token_name, :testcase) do
        'using personal access token' | :personal_access_token | 'Personal access token' | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347597'
        'using ci job token'          | :ci_job_token          | 'CI Job Token'          | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347595'
        'using group deploy token'    | :group_deploy_token    | 'Deploy Token'          | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347596'
      end

      with_them do
        let(:auth_token_password) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token.token, project: project)
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token.token, project: another_project)
          when :ci_job_token
            package_project_inbound_job_token_disabled
            client_project_inbound_job_token_disabled
            '${CI_JOB_TOKEN}'
          when :group_deploy_token
            use_ci_variable(name: 'GROUP_DEPLOY_TOKEN', value: group_deploy_token.token, project: project)
            use_ci_variable(name: 'GROUP_DEPLOY_TOKEN', value: group_deploy_token.token, project: another_project)
          end
        end

        let(:auth_token_username) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token.user.username}\""
          when :ci_job_token
            'gitlab-ci-token'
          when :group_deploy_token
            "\"#{group_deploy_token.username}\""
          end
        end

        it 'publishes a nuget package at the project endpoint and installs it from the group endpoint', :blocking, testcase: params[:testcase] do
          Flow::Login.sign_in

          nuget_upload_yaml = ERB.new(read_fixture('package_managers/nuget', 'nuget_upload_package.yaml.erb')).result(binding)

          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
              { action: 'update', file_path: '.gitlab-ci.yml', content: nuget_upload_yaml }
            ])
          end

          project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          another_project.visit!

          nuget_install_yaml = ERB.new(read_fixture('package_managers/nuget', 'nuget_install_package.yaml.erb')).result(binding)

          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            create(:commit, project: another_project, commit_message: 'Add new csproj file', actions: [
              {
                action: 'create',
                file_path: 'otherdotnet.csproj',
                content: <<~XML
                  <Project Sdk="Microsoft.NET.Sdk">
                    <PropertyGroup>
                      <OutputType>Exe</OutputType>
                      <TargetFramework>net7.0</TargetFramework>
                    </PropertyGroup>
                  </Project>
                XML
              },
              { action: 'update', file_path: '.gitlab-ci.yml', content: nuget_install_yaml }
            ])
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('install')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.group.visit!

          Page::Group::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)
          end
        end
      end
    end
  end
end
