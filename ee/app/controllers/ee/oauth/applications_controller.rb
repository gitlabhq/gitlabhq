module EE
  module Oauth
    module ApplicationsController
      protected

      def redirect_to_oauth_application_page
        raise NotImplementedError unless defined?(super)

        log_audit_event

        super
      end
    end
  end
end
