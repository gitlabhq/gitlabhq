# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, feature_category: :package_registry,
    requires_admin: 'Updates application settings' do
    describe 'Helm Registry', :external_api_calls do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:package_name) { "gitlab_qa_helm-#{SecureRandom.hex(8)}" }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'helm' }

      before do
        Flow::Login.sign_in
        package_project.visit!
      end

      context 'with ci deploy token' do
        include_context 'packages registry qa scenario with runner'

        let(:username) { 'gitlab-ci-token' }
        let(:access_token) do
          package_project_inbound_job_token_disabled
          client_project_inbound_job_token_disabled
          '${CI_JOB_TOKEN}'
        end

        before do
          Runtime::ApplicationSettings.set_application_settings(enforce_ci_inbound_job_token_scope_enabled: false)
        end

        it "pushes and pulls a helm chart",
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/565066' do
          helm_upload_yaml = ERB.new(read_fixture('package_managers/helm',
            'helm_upload_package.yaml.erb')).result(binding)
          helm_chart_yaml = ERB.new(read_fixture('package_managers/helm', 'Chart.yaml.erb')).result(binding)

          create(:commit, project: package_project, commit_message: 'Add .gitlab-ci.yml', actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: helm_upload_yaml },
            { action: 'create', file_path: 'Chart.yaml', content: helm_chart_yaml }
          ])

          Flow::Login.sign_in
          package_project.visit!
          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: package_project)

          package_project.visit_job('deploy')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 180)
          end

          Page::Project::Menu.perform(&:go_to_package_registry)
          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package_name)

            index.click_package(package_name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(name: package_name, version: package_version)
          end

          helm_install_yaml = ERB.new(read_fixture('package_managers/helm',
            'helm_install_package.yaml.erb')).result(binding)

          create(:commit, project: client_project, commit_message: 'Add .gitlab-ci.yml', actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: helm_install_yaml }
          ])

          client_project.visit!

          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: client_project)

          client_project.visit_job('pull')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 180)
          end
        end
      end

      context 'with other token types' do
        include_context 'packages registry qa scenario'

        let(:gitlab_address_with_port) { Support::GitlabAddress.address_with_port }
        let(:chart_yaml) do
          {
            file_path: 'Chart.yaml',
            content: <<~YAML
            apiVersion: v2
            name: #{package_name}
            version: #{package_version}
            description: A Helm chart for Kubernetes
            type: application
            appVersion: 1.0.0
            YAML
          }
        end

        before do
          with_fixtures([chart_yaml]) do |dir|
            Service::DockerRun::Helm.new(
              dir,
              gitlab_address_with_port: gitlab_address_with_port,
              package_project_id: package_project.id,
              channel: 'stable',
              package_name: package_name,
              package_version: package_version,
              username: username,
              token: token
            ).publish_and_install!
          end
        end

        shared_examples 'using a docker container' do |testcase|
          it 'pushes and pulls a helm chart', testcase: testcase do
            package_project.visit!

            Page::Project::Menu.perform(&:go_to_package_registry)
            Page::Project::Packages::Index.perform do |index|
              expect(index).to have_package(package_name)

              index.click_package(package_name)
            end
          end
        end

        context 'with a personal access token' do
          let(:username) { Runtime::User::Store.test_user.username }
          let(:token) { Runtime::User::Store.default_api_client.personal_access_token }

          it_behaves_like 'using a docker container', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/565067'
        end

        context 'with a project deploy token' do
          let(:username) { project_deploy_token.username }
          let(:token) { project_deploy_token.token }

          it_behaves_like 'using a docker container', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/565068'
        end
      end
    end
  end
end
