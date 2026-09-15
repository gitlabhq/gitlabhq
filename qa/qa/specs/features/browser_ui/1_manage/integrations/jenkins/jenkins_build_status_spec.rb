# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin, :skip_live_env, :skip_dedicated, feature_category: :code_testing do
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
      let(:project) { create(:project, api_client: user.api_client) }
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
        # Runs on a pass as well as a failure. A passing run shows whether Jenkins folded two
        # webhooks into one build, which is what lets the outcome be compared across runs.
        # The `after` hook removes the container, so this is the last chance to read the state.
        dump_jenkins_state
        jenkins_server&.remove!
        toggle_local_requests(false)
      end

      it 'integrates and displays build status for MR pipeline in GitLab' do
        setup_project_integration

        jenkins_integration = nil
        Support::Waiter.wait_until(max_duration: 10, sleep_interval: 1) do
          jenkins_integration = project.find_integration('jenkins')
        end

        expect(jenkins_integration).not_to be_nil, 'Jenkins integration did not save'
        expect(jenkins_integration[:active]).to be(true), 'Jenkins integration is not active'

        job = create_jenkins_job

        # The project starts empty, so nothing can push before this point. A push here gives
        # Jenkins a second webhook, and Jenkins can fold it into the build under test.
        pre_push_sha = branch_tip_sha

        expect(pre_push_sha).to be_nil,
          "The repository already held commit #{pre_push_sha} before the push. A second Jenkins " \
            'webhook is possible, and the build under test can hold the wrong commit.'

        commit = create(:commit, project: project, api_client: user.api_client, actions: [
          { action: 'create', file_path: 'test_file.txt', content: 'content' }
        ])

        pushed_sha = commit.api_response[:id]

        Runtime::Logger.info("Pre-push branch tip: #{pre_push_sha}. Pushed commit: #{pushed_sha}.")

        # Select the build by the commit that it checked out, and not by the build number. The
        # push above is the only push, so one build is expected. Any further webhook produces a
        # separate build, because the job allows concurrent builds, and this selection ignores it.
        build_id = nil
        build_found = Support::Waiter.wait_until(
          max_duration: 120, sleep_interval: 2, reload_page: false,
          raise_on_failure: false, retry_on_exception: true
        ) do
          build_id = job.build_number_for_revision(pushed_sha)
          !build_id.nil?
        end

        expect(build_found).to be_truthy,
          "No Jenkins build checked out the pushed commit #{pushed_sha} within 120s. The push " \
            'did not reach Jenkins, or Jenkins built a different commit.'

        # getResult can hold a value while post-build steps still run, so isBuilding is the only
        # check that the result is final.
        build_finished = Support::Waiter.wait_until(
          max_duration: 120, sleep_interval: 2, reload_page: false,
          raise_on_failure: false, retry_on_exception: true
        ) do
          job.build_running?(build_id) == false
        end

        expect(build_finished).to be_truthy,
          "Jenkins build ##{build_id} did not report as finished within 120s. It is still " \
            'building, the build was not found, or the Jenkins API is unreachable.'

        # A lambda keeps the log request out of a run that passes. Ruby evaluates a String
        # argument before `expect` runs, and RSpec calls a callable message only on a failure.
        expect(job.build_status(build_id)).to eql(:success),
          -> { "Build ##{build_id} failed or is not found: #{job.build_log(build_id)}" }

        statuses_url = Runtime::API::Request.new(
          user.api_client,
          "/projects/#{project.id}/repository/commits/#{pushed_sha}/statuses"
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

          statuses.is_a?(Array) &&
            statuses.any? { |status| status[:name] == 'jenkins' && status[:status] == 'success' }
        end

        # The poll accepts only a `success` status. On a timeout, log every status that the
        # pushed commit holds, so the log shows whether a `pending` or a `failed` status arrived.
        dump_commit_statuses(pushed_sha) unless jenkins_status_received

        expect(jenkins_status_received).to be_truthy,
          "Jenkins reported build success but no 'success' commit status reached GitLab within 60s"

        Flow::Login.sign_in(as: user)

        project.visit!

        # A commit status creates a pipeline for the commit that it names. The repository holds
        # one commit, which the assertion above enforces, so the project holds one pipeline and
        # the latest one is the pipeline under test.
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |show|
          expect(show).to have_build('jenkins', status: :success, wait: 15)
        end
      end

      private

      # Log the job's builds (number, result, causes, revision) and the Jenkins queue. The line
      # carries the example outcome, so a set of runs shows whether a folded build (two
      # GitLabWebHookCause entries) and a failure occur together.
      # Must run before the container is removed, otherwise the evidence is gone.
      def dump_jenkins_state
        outcome = RSpec.current_example&.exception ? 'failed' : 'passed'

        Runtime::Logger.info("Jenkins state (example #{outcome}): #{jenkins_client.state_dump(jenkins_project_name)}")
      rescue StandardError => e
        Runtime::Logger.warn("Could not read the Jenkins state: #{e.class}: #{e.message}")
      end

      # The tip of the project's default branch.
      #
      # @return [String, nil] the SHA, or nil if the request fails
      def branch_tip_sha
        response = Support::API.get(Runtime::API::Request.new(
          user.api_client, "/projects/#{project.id}/repository/commits", per_page: '1'
        ).url)

        # An empty repository and a failed request both give nil. The response code separates
        # them, so log it. Narrow this to the code that an empty repository returns once a run
        # has shown which code that is.
        unless response.code == Support::API::HTTP_STATUS_OK
          Runtime::Logger.info(
            "Could not list the commits (#{response.code}). The repository is empty, or the read failed."
          )
          return
        end

        Support::API.parse_body(response).first&.dig(:id)
      rescue StandardError => e
        Runtime::Logger.warn("Could not read the branch tip: #{e.class}: #{e.message}")
        nil
      end

      # Log every commit status that GitLab holds for one commit. The poll accepts only a
      # `success` status, so it reports nothing about a `pending` or a `failed` status. This
      # shows which states did arrive.
      #
      # @param sha [String] the commit to read
      def dump_commit_statuses(sha)
        response = Support::API.get(Runtime::API::Request.new(
          user.api_client, "/projects/#{project.id}/repository/commits/#{sha}/statuses"
        ).url)

        Runtime::Logger.info("Commit statuses for #{sha} (#{response.code}): #{response.body}")
      rescue StandardError => e
        Runtime::Logger.warn("Could not read the commit statuses: #{e.class}: #{e.message}")
      end

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
          # The spec opens no merge request, and the Jenkins job sets `triggerOnMergeRequest`
          # to false. A merge request event would only add webhook traffic.
          merge_requests_events: false
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
        # Without a root URL Jenkins sends `unconfigured-jenkins-location` to GitLab in every
        # commit status target_url.
        jenkins_client.configure_jenkins_location(patch_host_name(jenkins_server.host_address, 'jenkins-server'))

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
