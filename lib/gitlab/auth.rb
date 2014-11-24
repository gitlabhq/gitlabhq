module Gitlab
  class Auth
    def find(login, password)
      user = User.by_login(login)

      # If no user is found, or it's an LDAP server, try LDAP.
      #   LDAP users are only authenticated via LDAP
      if user.nil? || user.ldap_user?
        # Second chance - try LDAP authentication
        return nil unless Gitlab::LDAP::Config.enabled?

        Gitlab::LDAP::Authentication.login(login, password)
      else
        user if user.valid_password?(password)
      end
    end
  end
end
