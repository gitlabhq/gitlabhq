module EE
  module OmniauthCallbacksController
    protected

    def fail_login
      log_failed_login(@user.username, oauth['provider'])

      super
    end

    alias_method :fail_ldap_login, :fail_login

    private

    def log_failed_login(author, provider)
      ::AuditEventService.new(author,
                            nil,
                            ip_address: request.remote_ip,
                            with: provider)
          .for_failed_login.unauth_security_event
    end
  end
end
