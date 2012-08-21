class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # Extend the standard message generation to accept our custom exception
  def failure_message
    exception = env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= exception.message      if exception.respond_to?(:message)
    error ||= env["omniauth.error.type"].to_s
    error.to_s.humanize if error
  end
 
  def ldap
    # We only find ourselves here if the authentication to LDAP was successful.
    @user = User.find_for_ldap_auth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      @user.remember_me = true
    end
    sign_in_and_redirect @user
  end

end
