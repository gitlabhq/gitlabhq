module Ci
  module API
    module Helpers
      BUILD_TOKEN_HEADER = "HTTP_BUILD_TOKEN"
      BUILD_TOKEN_PARAM = :token
      UPDATE_RUNNER_EVERY = 60

      def authenticate_runners!
        forbidden! unless params[:token] == GitlabCi::REGISTRATION_TOKEN
      end

      def authenticate_runner!
        forbidden! unless current_runner
      end

      def authenticate_project_token!(project)
        forbidden! unless project.valid_token?(params[:project_token])
      end

      def authenticate_build_token!(build)
        token = (params[BUILD_TOKEN_PARAM] || env[BUILD_TOKEN_HEADER]).to_s
        forbidden! unless token && build.valid_token?(token)
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

      def update_runner_info
        return unless params["info"].present?
        info = attributes_for_keys(["name", "version", "revision", "platform", "architecture"], params["info"])
        current_runner.update(info)
      end

      def max_artifacts_size
        current_application_settings.max_artifacts_size.megabytes.to_i
      end
    end
  end
end
