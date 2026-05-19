# frozen_string_literal: true

module API
  module Ci
    module Helpers
      module Runner
        include Gitlab::Utils::StrongMemoize

        prepend_mod_with('API::Ci::Helpers::Runner') # rubocop: disable Cop/InjectEnterpriseEditionModule

        JOB_TOKEN_HEADER = 'HTTP_JOB_TOKEN'
        JOB_TOKEN_PARAM = :token
        LEGACY_SYSTEM_XID = '<legacy>'
        RUNNER_TOKEN_HEADER = 'Runner-Token'

        def authenticate_runner!(ensure_runner_manager: true, creation_state: nil)
          track_runner_authentication
          forbidden! unless current_runner

          set_current_organization_from_runner(current_runner)

          current_runner.heartbeat(creation_state: creation_state) if ensure_runner_manager
          return unless ensure_runner_manager

          runner_details = get_runner_details_from_request
          current_runner_manager&.heartbeat(runner_details)
        end

        def authenticate_runner_from_header!
          track_runner_authentication
          forbidden! unless current_runner_from_header

          set_current_organization_from_runner(current_runner_from_header)
        end

        def get_runner_details_from_request
          return get_runner_ip unless params['info'].present?

          attributes_for_keys(%w[name version revision platform architecture executor labels], params['info'])
            .merge(get_system_id_from_request)
            .merge(get_runner_config_from_request)
            .merge(get_runner_ip)
            .merge(get_runner_features_from_request)
        end

        def get_system_id_from_request
          return { system_id: params[:system_id] } if params.include?(:system_id)

          {}
        end

        def get_runner_ip
          { ip_address: ip_address }
        end

        def current_runner
          token = params[:token]

          load_balancer_stick_request(::Ci::Runner, :runner, token) if token

          strong_memoize(:current_runner) do
            ::Ci::Runner.find_by_token(token.to_s)
          end
        end

        def current_runner_from_header
          token = headers[RUNNER_TOKEN_HEADER]

          load_balancer_stick_request(::Ci::Runner, :runner, token) if token

          strong_memoize(:current_runner_from_header) do
            ::Ci::Runner.find_by_token(token.to_s)
          end
        end

        def current_runner_manager
          strong_memoize(:current_runner_manager) do
            system_xid = params.fetch(:system_id, LEGACY_SYSTEM_XID)
            current_runner&.ensure_manager(system_xid)
          end
        end

        def track_runner_authentication
          runner = current_runner || current_runner_from_header

          if runner
            metrics.increment_runner_authentication_success_counter(runner_type: runner.runner_type)
          else
            metrics.increment_runner_authentication_failure_counter
          end
        end

        # HTTP status codes to terminate the job on GitLab Runner:
        # - 403
        def authenticate_job!(heartbeat_runner: false, fail_on_expired_token: false)
          # 404 is not returned here because we want to terminate the job if it's
          # running. A 404 can be returned from anywhere in the networking stack which is why
          # we are explicit about a 403, we should improve this in
          # https://gitlab.com/gitlab-org/gitlab/-/issues/327703
          forbidden! unless current_job

          # Ensure we go through the Ci::AuthJobFinder as part of this authentication
          begin
            job = job_from_token

            forbidden! unless job
          rescue ::Ci::AuthJobFinder::DeletedProjectError => e
            log_job_auth_failure(e.job, 'project_deleted')
            forbidden!('Project has been deleted!')
          rescue ::Ci::AuthJobFinder::ErasedJobError => e
            log_job_auth_failure(e.job, 'job_erased')
            forbidden!('Job has been erased!')
          rescue ::Ci::AuthJobFinder::NotRunningJobError => e
            log_job_auth_failure(e.job, 'job_not_running')
            job_forbidden!(e.job, 'Job is not processing on runner')
          rescue ::Ci::AuthJobFinder::ExpiredJobTokenError => e
            if fail_on_expired_token
              dropped = \
                begin
                  e.job.drop(:job_token_expired)
                rescue ActiveRecord::StaleObjectError
                  false
                end

              log_job_auth_failure(e.job, dropped ? 'job_dropped_token_expired' : 'job_token_expired')
            else
              log_job_auth_failure(e.job, 'job_token_expired')
            end

            job_forbidden!(e.job, 'Job token has expired')
          end

          # Make sure that composite identity is propagated to `PipelineProcessWorker`
          # when the build's status change.
          # TODO: Once https://gitlab.com/gitlab-org/gitlab/-/issues/490992 is done we should
          # remove this because it will be embedded in `Ci::AuthJobFinder`.
          ::Gitlab::Auth::Identity.link_from_job(job)

          # Only some requests (like updating the job or patching the trace) should trigger
          # runner heartbeat. Operations like artifacts uploading are executed in context of
          # the running job and in the job environment, which in many cases will cause the IP
          # to be updated to not the expected value. And operations like artifacts downloads can
          # be done even after the job is finished and from totally different runners - while
          # they would then update the connection status of not the runner that they should.
          # Runner requests done in context of job authentication should explicitly define when
          # the heartbeat should be triggered.
          if heartbeat_runner
            job.runner&.heartbeat
            job.runner_manager&.heartbeat(get_runner_ip)
          end

          job
        end

        def authenticate_job_via_dependent_job!
          # Use primary for both main and non-main databases as authenticating in the scope of runners will load
          # Ci::Build model and other standard authn related models like License, Project and User.
          ::Gitlab::Database::LoadBalancing::SessionMap
            .with_sessions.use_primary { authenticate! }

          forbidden! unless current_job
          forbidden! unless can?(current_user, :read_build, current_job)
          forbidden! unless current_authenticated_job
        end

        # current_job is queried by URL :id param with no authentication
        def current_job
          id = params[:id]

          load_balancer_stick_request(::Ci::Build, :build, id) if id

          strong_memoize(:current_job) do
            ::Ci::Build.find_by_id(id)
          end
        end

        # The token used by runner to authenticate a request.
        # In most cases, the runner uses the token belonging to the requested job.
        # However, when requesting for job artifacts, the runner would use
        # the token that belongs to downstream jobs that depend on the job that owns
        # the artifacts.
        def job_token
          @job_token ||= (params[JOB_TOKEN_PARAM] || env[JOB_TOKEN_HEADER]).to_s
        end

        def job_from_token
          return unless current_job

          found_job = ::Ci::AuthJobFinder.new(token: job_token).execute!

          return unless found_job

          unless current_job == found_job
            log_job_auth_failure(found_job, 'job_token_mismatch')
            return
          end

          current_job
        end
        strong_memoize_attr :job_from_token

        def job_forbidden!(job, reason)
          header 'Job-Status', job.status
          forbidden!(reason)
        end

        def set_application_context
          if current_job
            Gitlab::ApplicationContext.push(job: current_job, runner: current_runner)
          elsif current_runner
            Gitlab::ApplicationContext.push(runner: current_runner)
          end

          # Idempotent: organization_assigned guard in the callee prevents
          # double-assignment when authenticate_runner! already set it.
          set_current_organization_from_runner(current_runner)
        end

        def track_ci_minutes_usage!(_build)
          # noop: overridden in EE
        end

        def audit_download(build, filename)
          # noop: overridden in EE
        end

        def check_if_backoff_required!
          return unless Gitlab::Database::Migrations::RunnerBackoff::Communicator.backoff_runner?

          too_many_requests!('Executing database migrations. Please retry later.', retry_after: 1.minute)
        end

        def job_router_enabled?(runner)
          if runner.instance_type?
            return Feature.enabled?(:job_router_instance_runners, runner) || Feature.enabled?(:job_router, :instance)
          end

          Feature.enabled?(:job_router, runner.owner&.root_ancestor)
        end

        private

        # rubocop:disable Gitlab/AvoidCurrentOrganization -- Runner API does not go
        # through standard set_current_organization
        def set_current_organization_from_runner(runner)
          return if ::Current.organization_assigned
          return if runner.nil? || runner.instance_type?

          ::Current.organization = ::Organizations::Organization.find_by_id_with_isolation(runner.organization_id)
        end
        # rubocop:enable Gitlab/AvoidCurrentOrganization

        def processing_on_runner?(job)
          job.running? || job.canceling?
        end

        def get_runner_config_from_request
          { config: attributes_for_keys(%w[gpus], params.dig('info', 'config')) }
        end

        def get_runner_features_from_request
          { runtime_features: attributes_for_keys(%w[features], params['info'])['features'] }.compact
        end

        def metrics
          strong_memoize(:metrics) { ::Gitlab::Ci::Runner::Metrics.new }
        end

        def log_job_auth_failure(job, reason)
          Gitlab::AppLogger.info({
            class: self.class.name,
            job_id: job.id,
            job_status: job.status,
            job_user_id: job.user_id,
            job_project_id: job.project_id,
            auth_fail_reason: reason,
            message: "Job auth error"
          }.merge(Gitlab::ApplicationContext.current))
        end
      end
    end
  end
end
