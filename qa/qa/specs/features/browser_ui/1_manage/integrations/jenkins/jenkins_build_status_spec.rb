# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin, :skip_live_env, feature_category: :code_testing do
    describe 'Jenkins integration' do
      let(:jenkins_server) { Service::DockerRun::Jenkins.new }

      let(:jenkins_client) do
        Vendor::Jenkins::Client.new(
          jenkins_server.host_name,
          port: jenkins_server.port,
          user: Runtime::Env.jenkins_admin_username,
          password: Runtime::Env.jenkins_admin_password
        )
      end

      let(:jenkins_project_name) { "gitlab_jenkins_#{SecureRandom.hex(5)}" }
      let(:connection_name) { 'gitlab-connection' }
      let(:user) { create(:user, &:create_personal_access_token!) }
      let(:project) { create(:project, :with_readme, api_client: user.api_client) }
      let(:access_token) { user.personal_access_token.token }

      before do
        toggle_local_requests(true)
        jenkins_server.register!

        Support::Waiter.wait_until(max_duration: 30, reload_page: false, retry_on_exception: true, sleep_interval: 1) do
          jenkins_client.ready?
        end

        configure_gitlab_jenkins
      end

      after do
        jenkins_server&.remove!
        toggle_local_requests(false)
      end

      it 'integrates and displays build status for MR pipeline in GitLab',
        quarantine: { issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/43780',
                      type: 'flaky' } do
        setup_project_integration

        jenkins_integration = nil
        Support::Waiter.wait_until(max_duration: 10, sleep_interval: 1) do
          jenkins_integration = project.find_integration('jenkins')
        end

        expect(jenkins_integration).not_to be_nil, 'Jenkins integration did not save'
        expect(jenkins_integration[:active]).to be(true), 'Jenkins integration is not active'

        job = create_jenkins_job

        commit = create(:commit, project: project, api_client: user.api_client, actions: [
          { action: 'create', file_path: 'test_file.txt', content: 'content' }
        ])

        Support::Waiter.wait_until(max_duration: 60, raise_on_failure: false, reload_page: false) do
          job.status == :success
        end

        expect(job.status).to eql(:success), "Build failed or is not found: #{job.log}"

        statuses_url = Runtime::API::Request.new(
          user.api_client,
          "/projects/#{project.id}/repository/commits/#{commit.api_response[:id]}/statuses"
        ).url

        jenkins_status_received = Support::Waiter.wait_until(
          max_duration: 60,
          sleep_interval: 2,
          reload_page: false,
          raise_on_failure: false,
          retry_on_exception: true,
          message: 'Waiting for Jenkins commit status to reach GitLab'
        ) do
          response = Support::API.get(statuses_url)

          next false unless response.code == Support::API::HTTP_STATUS_OK

          statuses = Support::API.parse_body(response)
          statuses.is_a?(Array) && statuses.any? { |status| status[:name] == 'jenkins' && status[:status] == 'success' }
        end

        expect(jenkins_status_received).to be_truthy,
          "Jenkins reported build success but no 'success' commit status reached GitLab within 60s"

        Flow::Login.sign_in(as: user)

        project.visit!

        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |show|
          expect(show).to have_build('jenkins', status: :success, wait: 15)
        end
      end

      private

      def setup_project_integration
        patched_jenkins_url = patch_host_name(jenkins_server.host_address, 'jenkins-server')

        integration_url = Runtime::API::Request.new(
          user.api_client,
          "/projects/#{project.id}/integrations/jenkins"
        ).url

        put_response = Support::API.put(integration_url, {
          jenkins_url: patched_jenkins_url,
          project_name: jenkins_project_name,
          username: jenkins_server.username,
          password: jenkins_server.password,
          push_events: true,
          merge_requests_events: true
        })

        unless put_response.code == Support::API::HTTP_STATUS_OK
          raise "Failed to configure Jenkins integration via API (#{put_response.code}): #{put_response.body}"
        end

        # Re-fetch the integration to confirm it was actually saved and active,
        # not just that the PUT returned 200 (a wrong key silently misconfigures).
        get_response = Support::API.get(integration_url)

        unless get_response.code == Support::API::HTTP_STATUS_OK
          raise "Failed to fetch Jenkins integration after configuration (#{get_response.code}): #{get_response.body}"
        end

        integration = Support::API.parse_body(get_response)

        raise "Jenkins integration is not active after configuration" unless integration[:active]

        properties = integration[:properties] || {}

        raise "jenkins_url mismatch: expected #{patched_jenkins_url}, got #{properties[:jenkins_url]}" \
          if properties[:jenkins_url] != patched_jenkins_url

        raise "project_name mismatch: expected #{jenkins_project_name}, got #{properties[:project_name]}" \
          if properties[:project_name] != jenkins_project_name
      end

      def create_jenkins_job
        jenkins_client.create_job jenkins_project_name do |job|
          job.gitlab_connection = connection_name
          job.description = 'Just a job'
          job.repo_url = patch_host_name(project.repository_http_location.git_uri, 'gitlab')
          job.shell_command = 'sleep 5'
        end
      end

      def configure_gitlab_jenkins
        jenkins_client.configure_gitlab_plugin(
          patch_host_name(Runtime::Scenario.gitlab_address, 'gitlab'),
          connection_name: connection_name,
          access_token: access_token,
          read_timeout: 20,
          connection_timeout: 10
        )
      end

      def patch_host_name(host_name, container_name)
        return host_name unless host_name.include?('localhost')

        ip_address = `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' #{container_name}`
                       .strip
        host_name.gsub('localhost', ip_address)
      end

      def toggle_local_requests(on)
        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: on)
      end
    end
  end
end
