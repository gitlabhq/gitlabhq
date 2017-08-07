module EE
  module OmniauthCallbacksController
    protected

    def fail_login
      log_failed_login(@user.username, oauth['provider'])

      error_message = @user.errors.full_messages.to_sentence

      return redirect_to omniauth_error_path(oauth['provider'], error: error_message)
    end

    def fail_ldap_login
      log_failed_login(@user.username, oauth['provider'])

      flash[:alert] = 'Access denied for your LDAP account.'

      redirect_to new_user_session_path
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
