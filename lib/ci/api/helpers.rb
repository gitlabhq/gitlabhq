module Ci
  module API
    module Helpers
      UPDATE_RUNNER_EVERY = 60

      def check_enable_flag!
        unless current_application_settings.ci_enabled
          render_api_error!('400 (Bad request) CI is disabled', 400)
        end
      end

      def authenticate_runners!
        forbidden! unless params[:token] == GitlabCi::REGISTRATION_TOKEN
      end

      def authenticate_runner!
        forbidden! unless current_runner
      end

      def authenticate_project_token!(project)
        forbidden! unless project.valid_token?(params[:project_token])
      end

      def update_runner_last_contact
        if current_runner.contacted_at.nil? || Time.now - current_runner.contacted_at >= UPDATE_RUNNER_EVERY
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
    end
  end
end
