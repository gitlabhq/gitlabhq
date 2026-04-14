# frozen_string_literal: true

module QA
  RSpec.describe 'Package', feature_category: :package_registry do
    describe 'npm Registry group level endpoint', :object_storage, :external_api_calls,
      feature_category: :package_registry do
      include Runtime::Fixtures

      let!(:project) { create(:project, name: 'npm-group-publish') }
      let!(:group) { project.group }
      let!(:registry_scope) { group.sandbox.name }

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
      let(:package) { build(:package, name: "@#{registry_scope}/#{project.name}", project: project) }

      before do
        Flow::Login.sign_in
      end

      context 'with ci job token' do
        let!(:another_project) { create(:project, name: 'npm-group-install', group: group) }
        let!(:runner) do
          create(:group_runner,
            name: "qa-runner-#{SecureRandom.hex(6)}",
            tags: ["runner-for-#{group.name}"],
            executor: :docker,
            group: group)
        end

        let(:auth_token) { '${CI_JOB_TOKEN}' }

        after do
          runner.remove_via_api!
        end

        it 'push and pull a npm package via CI',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/565159' do
          npm_upload_yaml = ERB.new(read_fixture('package_managers/npm',
            'npm_upload_package_group.yaml.erb')).result(binding)
          package_json = ERB.new(read_fixture('package_managers/npm', 'package.json.erb')).result(binding)

          create(:commit, project: project, actions: [
            {
              action: 'create',
              file_path: '.gitlab-ci.yml',
              content: npm_upload_yaml
            },
            {
              action: 'create',
              file_path: 'package.json',
              content: package_json
            }
          ])

          project.visit!
          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)

          project.visit_job('deploy')
          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 180)
          end

          npm_install_yaml = ERB.new(read_fixture('package_managers/npm',
            'npm_install_package_group.yaml.erb')).result(binding)

          create(:commit, project: another_project, commit_message: 'Add .gitlab-ci.yml', actions: [
            {
              action: 'create',
              file_path: '.gitlab-ci.yml',
              content: npm_install_yaml
            }
          ])

          another_project.visit!
          Flow::Pipeline.wait_for_pipeline_creation_via_api(project: another_project)

          another_project.visit_job('install')

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 180)
            job.close_dap_panel_if_exists
            job.click_browse_button
          end

          Page::Project::Artifact::Show.perform do |artifacts|
            artifacts.go_to_directory('node_modules')
            artifacts.go_to_directory("@#{registry_scope}")
            expect(artifacts).to have_content(project.name.to_s)
          end

          project.visit!
          Page::Project::Menu.perform(&:go_to_package_registry)
          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)

            index.click_package(package.name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(name: package.name, version: "1.0.0")
          end
        end
      end

      context 'with other token types' do
        include_context 'npm docker container publish and install'

        let(:install_registry_url) { "#{gitlab_address_without_port}/api/v4/groups/#{group.id}/-/packages/npm/" }

        context 'with a personal access token' do
          let(:token) { Runtime::User::Store.test_user.current_personal_access_token }

          it_behaves_like 'using a docker container',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/565158'
        end

        context 'with a project deploy token' do
          let(:token) { project_deploy_token.token }

          it_behaves_like 'using a docker container',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/565157'
        end
      end
    end
  end
end
