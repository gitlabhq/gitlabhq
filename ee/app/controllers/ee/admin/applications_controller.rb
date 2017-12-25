module EE
  module Admin
    module ApplicationsController
      extend ::Gitlab::Utils::Override

      protected

      override :redirect_to_admin_page
      def redirect_to_admin_page
        log_audit_event

        super
      end
    end
  end
end
