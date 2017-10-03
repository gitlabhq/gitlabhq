module EE
  module Emails
    module BaseService
      private

      def log_audit_event(options = {})
        ::AuditEventService.new(@current_user, @user, options)
            .for_email(@email).security_event
      end
    end
  end
end
