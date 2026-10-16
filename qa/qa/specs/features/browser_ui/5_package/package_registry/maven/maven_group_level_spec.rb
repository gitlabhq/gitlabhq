# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, feature_category: :package_registry do
    describe 'Maven group level endpoint', :external_api_calls do
      include Runtime::Fixtures
      include Support::API
      include_context 'packages registry qa scenario with runner'

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:token) { '${CI_JOB_TOKEN}' }
      let(:maven_header_name) { 'Job-Token' }

      it 'publishes a package from one project and installs it in another through the group endpoint' do
        allowlist = Runtime::API::Request.new(api_client, "/projects/#{package_project.id}/job_token_scope/allowlist")
        response = post(allowlist.url, { target_project_id: client_project.id })
        expect(response.code).to eq(Support::API::HTTP_STATUS_CREATED)

        commit_maven_files(project: package_project, fixture_dir: 'producer')

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
          expect(show).to have_package_info(name: nil, version: package_version)
        end

        commit_maven_files(project: client_project, fixture_dir: 'consumer')

        client_project.visit_job('install')
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 180)
        end
      end

      def commit_maven_files(project:, fixture_dir:)
        templates = { '.gitlab-ci.yml' => 'gitlab_ci.yaml.erb', 'pom.xml' => 'pom.xml.erb',
                      'settings.xml' => 'settings.xml.erb' }
        actions = templates.map do |file_path, template|
          content = ERB.new(read_fixture("package_managers/maven/group/#{fixture_dir}", template)).result(binding)

          { action: 'create', file_path: file_path, content: content }
        end

        create(:commit, project: project, actions: actions)
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
      end
    end
  end
end
