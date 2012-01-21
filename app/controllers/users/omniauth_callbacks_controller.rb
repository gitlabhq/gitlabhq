class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
 
  def ldap
    # We only find ourselves here if the authentication to LDAP was successful.
    ldap = request.env["omniauth.auth"]["extra"]["raw_info"]
    username = ldap.sAMAccountName[0].to_s
    email = ldap.proxyaddresses[0][5..-1].to_s
 
    if @user = User.find_by_email(email)
        sign_in_and_redirect root_path
    else
      password = User.generate_random_password
        @user = User.create(:name => username,
                            :email => email,
                            :password => password,
                            :password_confirmation => password
                           )
        sign_in_and_redirect @user
    end
  end

end
