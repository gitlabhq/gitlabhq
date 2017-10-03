module EE
  module Admin
    module ApplicationsController
      protected

      def redirect_to_admin_page
        raise NotImplementedError unless defined?(super)

        log_audit_event

        super
      end
    end
  end
end
