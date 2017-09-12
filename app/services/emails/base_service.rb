module Emails
  class BaseService
    def initialize(current_user, user, opts)
      @current_user = current_user
      @user = user
      @email = opts[:email]
    end

    def log_audit_event(options = {})
      AuditEventService.new(@current_user, @user, options)
          .for_email(@email).security_event
    end
  end
end
