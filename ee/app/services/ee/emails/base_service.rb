module EE
  module Emails
    module BaseService
      def initialize(current_user, user, opts)
        @current_user = current_user

        super(user, opts)
      end

      private

      def log_audit_event(options = {})
        AuditEventService.new(@current_user, @user, options)
            .for_email(@email).security_event
      end
    end
  end
end
