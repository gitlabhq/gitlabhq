module API
  module Helpers
    module Runner
      include Gitlab::CurrentSettings

      JOB_TOKEN_HEADER = 'HTTP_JOB_TOKEN'.freeze
      JOB_TOKEN_PARAM = :token
      UPDATE_RUNNER_EVERY = 10 * 60

      def runner_registration_token_valid?
        ActiveSupport::SecurityUtils.variable_size_secure_compare(params[:token],
                                                                  current_application_settings.runners_registration_token)
      end

      def get_runner_version_from_params
        return unless params['info'].present?

        attributes_for_keys(%w(name version revision platform architecture), params['info'])
      end

      def authenticate_runner!
        forbidden! unless current_runner
      end

      def current_runner
        @runner ||= ::Ci::Runner.find_by_token(params[:token].to_s)
      end

      def update_runner_info
        return unless update_runner?

        current_runner.contacted_at = Time.now
        current_runner.assign_attributes(get_runner_version_from_params)
        current_runner.save if current_runner.changed?
      end

      def update_runner?
        # Use a random threshold to prevent beating DB updates.
        # It generates a distribution between [40m, 80m].
        #
        contacted_at_max_age = UPDATE_RUNNER_EVERY + Random.rand(UPDATE_RUNNER_EVERY)

        current_runner.contacted_at.nil? ||
          (Time.now - current_runner.contacted_at) >= contacted_at_max_age
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
        current_application_settings.max_artifacts_size.megabytes.to_i
      end
    end
  end
end
