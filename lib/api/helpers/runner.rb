# frozen_string_literal: true

module API
  module Helpers
    module Runner
      include Gitlab::Utils::StrongMemoize

      prepend_mod_with('API::Helpers::Runner') # rubocop: disable Cop/InjectEnterpriseEditionModule

      JOB_TOKEN_HEADER = 'HTTP_JOB_TOKEN'
      JOB_TOKEN_PARAM = :token

      def runner_registration_token_valid?
        ActiveSupport::SecurityUtils.secure_compare(params[:token], Gitlab::CurrentSettings.runners_registration_token)
      end

      def runner_registrar_valid?(type)
        Feature.disabled?(:runner_registration_control) || Gitlab::CurrentSettings.valid_runner_registrars.include?(type)
      end

      def authenticate_runner!
        forbidden! unless current_runner

        current_runner
          .heartbeat(get_runner_details_from_request)
      end

      def get_runner_details_from_request
        return get_runner_ip unless params['info'].present?

        attributes_for_keys(%w(name version revision platform architecture), params['info'])
          .merge(get_runner_config_from_request)
          .merge(get_runner_ip)
      end

      def get_runner_ip
        { ip_address: ip_address }
      end

      def current_runner
        token = params[:token]

        if token
          ::Gitlab::Database::LoadBalancing::RackMiddleware
            .stick_or_unstick(env, :runner, token)
        end

        strong_memoize(:current_runner) do
          ::Ci::Runner.find_by_token(token.to_s)
        end
      end

      # HTTP status codes to terminate the job on GitLab Runner:
      # - 403
      def authenticate_job!(require_running: true)
        job = current_job

        # 404 is not returned here because we want to terminate the job if it's
        # running. A 404 can be returned from anywhere in the networking stack which is why
        # we are explicit about a 403, we should improve this in
        # https://gitlab.com/gitlab-org/gitlab/-/issues/327703
        forbidden! unless job

        forbidden! unless job_token_valid?(job)

        forbidden!('Project has been deleted!') if job.project.nil? || job.project.pending_delete?
        forbidden!('Job has been erased!') if job.erased?

        if require_running
          job_forbidden!(job, 'Job is not running') unless job.running?
        end

        job.runner&.heartbeat(get_runner_ip)

        job
      end

      def current_job
        id = params[:id]

        if id
          ::Gitlab::Database::LoadBalancing::RackMiddleware
            .stick_or_unstick(env, :build, id)
        end

        strong_memoize(:current_job) do
          ::Ci::Build.find_by_id(id)
        end
      end

      def job_token_valid?(job)
        token = (params[JOB_TOKEN_PARAM] || env[JOB_TOKEN_HEADER]).to_s
        token && job.valid_token?(token)
      end

      def job_forbidden!(job, reason)
        header 'Job-Status', job.status
        forbidden!(reason)
      end

      def set_application_context
        return unless current_job

        Gitlab::ApplicationContext.push(
          user: -> { current_job.user },
          project: -> { current_job.project }
        )
      end

      def track_ci_minutes_usage!(_build, _runner)
        # noop: overridden in EE
      end

      private

      def get_runner_config_from_request
        { config: attributes_for_keys(%w(gpus), params.dig('info', 'config')) }
      end
    end
  end
end
