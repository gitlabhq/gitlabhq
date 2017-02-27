module API
  module Helpers
    module Runner
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
    end
  end
end
