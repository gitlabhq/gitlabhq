module Ci
  module API
    module Helpers
      BUILD_TOKEN_HEADER = "HTTP_BUILD_TOKEN"
      BUILD_TOKEN_PARAM = :token
      UPDATE_RUNNER_EVERY = 60

      def authenticate_runners!
        forbidden! unless runner_registration_token_valid?
      end

      def authenticate_runner!
        forbidden! unless current_runner
      end

      def authenticate_build_token!(build)
        token = (params[BUILD_TOKEN_PARAM] || env[BUILD_TOKEN_HEADER]).to_s
        forbidden! unless token && build.valid_token?(token)
      end

      def runner_registration_token_valid?
        params[:token] == current_application_settings.runners_registration_token
      end

      def update_runner_last_contact
        # Use a random threshold to prevent beating DB updates
        contacted_at_max_age = UPDATE_RUNNER_EVERY + Random.rand(UPDATE_RUNNER_EVERY)
        if current_runner.contacted_at.nil? || Time.now - current_runner.contacted_at >= contacted_at_max_age
          current_runner.update_attributes(contacted_at: Time.now)
        end
      end

      def current_runner
        @runner ||= Runner.find_by_token(params[:token].to_s)
      end

      def get_runner_version_from_params
        return unless params["info"].present?
        attributes_for_keys(["name", "version", "revision", "platform", "architecture"], params["info"])
      end

      def update_runner_info
        current_runner.assign_attributes(get_runner_version_from_params)
        current_runner.save if current_runner.changed?
      end

      def max_artifacts_size
        current_application_settings.max_artifacts_size.megabytes.to_i
      end
    end
  end
end
