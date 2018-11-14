# frozen_string_literal: true

module API
  module Helpers
    module Runner
      JOB_TOKEN_HEADER = 'HTTP_JOB_TOKEN'.freeze
      JOB_TOKEN_PARAM = :token

      def runner_registration_token_valid?
        ActiveSupport::SecurityUtils.variable_size_secure_compare(params[:token],
                                                                  Gitlab::CurrentSettings.runners_registration_token)
      end

      def authenticate_runner!
        forbidden! unless current_runner

        current_runner
          .update_cached_info(get_runner_details_from_request)
      end

      def get_runner_details_from_request
        return get_runner_ip unless params['info'].present?

        attributes_for_keys(%w(name version revision platform architecture), params['info'])
          .merge(get_runner_ip)
      end

      def get_runner_ip
        { ip_address: request.ip }
      end

      def current_runner
        @runner ||= ::Ci::Runner.find_by_token(params[:token].to_s)
      end

      def validate_job!(job)
        not_found! unless job

        project = job.project
        job_forbidden!(job, 'Project has been deleted!') if project.nil? || project.pending_delete?
        job_forbidden!(job, 'Job has been erased!') if job.erased?
        job_forbidden!(job, 'Not running!') unless job.running?
      end

      def authenticate_job_by_token!
        token = (params[JOB_TOKEN_PARAM] || env[JOB_TOKEN_HEADER]).to_s

        Ci::Build.find_by_token(token).tap do |job|
          validate_job!(job)
        end
      end

      # we look for a job that has ID and token matching
      def authenticate_job!
        authenticate_job_by_token!.tap do |job|
          job_forbidden!(job, 'Invalid Job ID!') unless job.id == params[:id]
        end
      end

      # we look for a job that has been shared via pipeline using the ID
      def authenticate_pipeline_job!
        job = authenticate_job_by_token!

        job.pipeline.builds.find(params[:id])
      end

      def max_artifacts_size
        Gitlab::CurrentSettings.max_artifacts_size.megabytes.to_i
      end

      def job_forbidden!(job, reason)
        header 'Job-Status', job.status
        forbidden!(reason)
      end
    end
  end
end
