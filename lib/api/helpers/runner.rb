# frozen_string_literal: true

module API
  module Helpers
    module Runner
      include Gitlab::Utils::StrongMemoize

      prepend_if_ee('EE::API::Helpers::Runner') # rubocop: disable Cop/InjectEnterpriseEditionModule

      JOB_TOKEN_HEADER = 'HTTP_JOB_TOKEN'
      JOB_TOKEN_PARAM = :token

      def runner_registration_token_valid?
        ActiveSupport::SecurityUtils.secure_compare(params[:token], Gitlab::CurrentSettings.runners_registration_token)
      end

      def authenticate_runner!
        forbidden! unless current_runner

        current_runner
          .heartbeat(get_runner_details_from_request)
      end

      def get_runner_details_from_request
        return get_runner_ip unless params['info'].present?

        attributes_for_keys(%w(name version revision platform architecture), params['info'])
          .merge(get_runner_ip)
      end

      def get_runner_ip
        { ip_address: ip_address }
      end

      def current_runner
        strong_memoize(:current_runner) do
          ::Ci::Runner.find_by_token(params[:token].to_s)
        end
      end

      def authenticate_job!(require_running: true)
        job = current_job

        not_found! unless job
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
        strong_memoize(:current_job) do
          ::Ci::Build.find_by_id(params[:id])
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
    end
  end
end
