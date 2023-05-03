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

        def authenticate_runner!(ensure_runner_manager: true, update_contacted_at: true)
          track_runner_authentication
          forbidden! unless current_runner

          runner_details = get_runner_details_from_request
          current_runner.heartbeat(runner_details, update_contacted_at: update_contacted_at)
          return unless ensure_runner_manager

          current_runner_manager&.heartbeat(runner_details, update_contacted_at: update_contacted_at)
        end

        def get_runner_details_from_request
          return get_runner_ip unless params['info'].present?

          attributes_for_keys(%w(name version revision platform architecture executor), params['info'])
            .merge(get_system_id_from_request)
            .merge(get_runner_config_from_request)
            .merge(get_runner_ip)
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

          if token
            ::Ci::Runner.sticking.stick_or_unstick_request(env, :runner, token)
          end

          strong_memoize(:current_runner) do
            ::Ci::Runner.find_by_token(token.to_s)
          end
        end

        def current_runner_manager
          strong_memoize(:current_runner_manager) do
            system_xid = params.fetch(:system_id, LEGACY_SYSTEM_XID)
            current_runner&.ensure_manager(system_xid) { |m| m.contacted_at = Time.current }
          end
        end

        def track_runner_authentication
          if current_runner
            metrics.increment_runner_authentication_success_counter(runner_type: current_runner.runner_type)
          else
            metrics.increment_runner_authentication_failure_counter
          end
        end

        # HTTP status codes to terminate the job on GitLab Runner:
        # - 403
        def authenticate_job!(heartbeat_runner: false)
          job = current_job

          # 404 is not returned here because we want to terminate the job if it's
          # running. A 404 can be returned from anywhere in the networking stack which is why
          # we are explicit about a 403, we should improve this in
          # https://gitlab.com/gitlab-org/gitlab/-/issues/327703
          forbidden! unless job

          forbidden! unless job.valid_token?(job_token)

          forbidden!('Project has been deleted!') if job.project.nil? || job.project.pending_delete?
          forbidden!('Job has been erased!') if job.erased?
          job_forbidden!(job, 'Job is not running') unless job.running?

          # Only some requests (like updating the job or patching the trace) should trigger
          # runner heartbeat. Operations like artifacts uploading are executed in context of
          # the running job and in the job environment, which in many cases will cause the IP
          # to be updated to not the expected value. And operations like artifacts downloads can
          # be done even after the job is finished and from totally different runners - while
          # they would then update the connection status of not the runner that they should.
          # Runner requests done in context of job authentication should explicitly define when
          # the heartbeat should be triggered.
          if heartbeat_runner
            job.runner&.heartbeat(get_runner_ip)
            job.runner_manager&.heartbeat(get_runner_ip)
          end

          job
        end

        def authenticate_job_via_dependent_job!
          authenticate!
          forbidden! unless current_job
          forbidden! unless can?(current_user, :read_build, current_job)
        end

        def current_job
          id = params[:id]

          if id
            ::Ci::Build
              .sticking
              .stick_or_unstick_request(env, :build, id)
          end

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

        def job_forbidden!(job, reason)
          header 'Job-Status', job.status
          forbidden!(reason)
        end

        def set_application_context
          return unless current_job

          Gitlab::ApplicationContext.push(job: current_job, runner: current_runner)
        end

        def track_ci_minutes_usage!(_build, _runner)
          # noop: overridden in EE
        end

        private

        def get_runner_config_from_request
          { config: attributes_for_keys(%w(gpus), params.dig('info', 'config')) }
        end

        def metrics
          strong_memoize(:metrics) { ::Gitlab::Ci::Runner::Metrics.new }
        end
      end
    end
  end
end
