module EE
  module PasswordsController
    prepended do
      before_action :log_audit_event, only: [:create]
    end

    private

    def log_audit_event
      AuditEventService.new(current_user,
                            resource,
                            action: :custom,
                            custom_message: 'Ask for password reset',
                            ip_address: request.remote_ip)
          .for_user(resource_params[:email]).unauth_security_event
    end
  end
end
