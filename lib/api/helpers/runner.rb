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

        yield if block_given?

        project = job.project
        forbidden!('Project has been deleted!') if project.nil? || project.pending_delete?
        forbidden!('Job has been erased!') if job.erased?
      end

      def authenticate_job!
        job = Ci::Build.find_by_id(params[:id])

        validate_job!(job) do
          forbidden! unless job_token_valid?(job)
        end

        job
      end

      def job_token_valid?(job)
        token = (params[JOB_TOKEN_PARAM] || env[JOB_TOKEN_HEADER]).to_s
        token && job.valid_token?(token)
      end

      def max_artifacts_size
        Gitlab::CurrentSettings.max_artifacts_size.megabytes.to_i
      end

      def runner_create_attributes(project = nil)
        attributes_for_keys(runner_create_attribute_keys(project))
          .merge(get_runner_details_from_request)
      end

      def runner_create_attribute_keys(project = nil)
        [:description, :locked, :run_untagged, :tag_list, :maximum_timeout]
      end

      def runner_update_attributes
        declared_params(include_missing: false)
      end
    end
  end
end
