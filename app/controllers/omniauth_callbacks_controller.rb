class OmniauthCallbacksController < Devise::OmniauthCallbacksController
 
  def ldap
    # We only find ourselves here if the authentication to LDAP was successful.
    omniauth = request.env["omniauth.auth"]["extra"]["raw_info"]
    @user = User.find_for_ldap_auth(omniauth)
    if @user.persisted?
      @user.remember_me = true
    end
    sign_in_and_redirect @user
  end

end
