module EE
  module Admin
    module ApplicationsController
      protected

      def redirect_to_profile_key_path
        raise NotImplementedError unless defined?(super)

        log_audit_event

        super
      end

      private

      def log_audit_event
        AuditEventService.new(current_user,
                              current_user,
                              action: :custom,
                              custom_message: 'Added SSH key',
                              ip_address: request.remote_ip)
            .for_user(@key.title).security_event
      end
    end
  end
end
