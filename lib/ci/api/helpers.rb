module Ci
  module API
    module Helpers
      PRIVATE_TOKEN_PARAM = :private_token
      PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN"
      ACCESS_TOKEN_PARAM = :access_token
      ACCESS_TOKEN_HEADER = "HTTP_ACCESS_TOKEN"
      UPDATE_RUNNER_EVERY = 60

      def current_user
        @current_user ||= begin
          options = {
            access_token: (params[ACCESS_TOKEN_PARAM] || env[ACCESS_TOKEN_HEADER]),
            private_token: (params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER]),
          }
          Ci::UserSession.new.authenticate(options.compact)
        end
      end

      def current_runner
        @runner ||= Ci::Runner.find_by_token(params[:token].to_s)
      end

      def authenticate!
        forbidden! unless current_user
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

      def update_runner_info
        return unless params["info"].present?
        info = attributes_for_keys(["name", "version", "revision", "platform", "architecture"], params["info"])
        current_runner.update(info)
      end

      # Checks the occurrences of required attributes, each attribute must be present in the params hash
      # or a Bad Request error is invoked.
      #
      # Parameters:
      #   keys (required) - A hash consisting of keys that must be present
      def required_attributes!(keys)
        keys.each do |key|
          bad_request!(key) unless params[key].present?
        end
      end

      def attributes_for_keys(keys, custom_params = nil)
        params_hash = custom_params || params
        attrs = {}
        keys.each do |key|
          attrs[key] = params_hash[key] if params_hash[key].present?
        end
        attrs
      end

      # error helpers

      def forbidden!
        render_api_error!('403 Forbidden', 403)
      end

      def bad_request!(attribute)
        message = ["400 (Bad request)"]
        message << "\"" + attribute.to_s + "\" not given"
        render_api_error!(message.join(' '), 400)
      end

      def not_found!(resource = nil)
        message = ["404"]
        message << resource if resource
        message << "Not Found"
        render_api_error!(message.join(' '), 404)
      end

      def unauthorized!
        render_api_error!('401 Unauthorized', 401)
      end

      def not_allowed!
        render_api_error!('Method Not Allowed', 405)
      end

      def render_api_error!(message, status)
        error!({ 'message' => message }, status)
      end

      private

      def abilities
        @abilities ||= begin
                         abilities = Six.new
                         abilities << Ability
                         abilities
                       end
      end
    end
  end
end
