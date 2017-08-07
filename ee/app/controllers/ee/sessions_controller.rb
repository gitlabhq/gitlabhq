module EE
  module SessionsController
    extend ActiveSupport::Concern

    prepended do
      after_action :log_failed_login, only: :new, if: :failed_login?
    end

    private

    def log_failed_login
      ::AuditEventService.new(request.filtered_parameters['user']['login'], nil, ip_address: request.remote_ip)
          .for_failed_login.unauth_security_event
    end

    def failed_login?
      env['warden.options'] && env['warden.options'][:action] == 'unauthenticated'
    end
  end
end
