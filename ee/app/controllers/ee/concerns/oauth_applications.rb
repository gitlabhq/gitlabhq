module EE
  module OauthApplications
    extend ActiveSupport::Concern

    def log_audit_event
      AuditEventService.new(current_user,
                            current_user,
                            action: :custom,
                            custom_message: 'OAuth access granted',
                            ip_address: request.remote_ip)
          .for_user(@application.name).security_event
    end
  end
end
