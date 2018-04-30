module EE
  module OmniauthCallbacksController
    extend ::Gitlab::Utils::Override

    protected

    override :fail_login
    def fail_login(user)
      log_failed_login(user.username, oauth['provider'])

      super
    end

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
