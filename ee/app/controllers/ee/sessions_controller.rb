module EE
  module SessionsController
    extend ActiveSupport::Concern

    private

    def log_failed_login
      ::AuditEventService.new(request.filtered_parameters['user']['login'], nil, ip_address: request.remote_ip)
          .for_failed_login.unauth_security_event

      super
    end
  end
end
