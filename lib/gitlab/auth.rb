module Gitlab
  class Auth
    def find(login, password)
      user = User.find_by(email: login) || User.find_by(username: login)

      if user.nil? || user.ldap_user?
        # Second chance - try LDAP authentication
        return nil unless ldap_conf.enabled

        Gitlab::LDAP::User.authenticate(login, password)
      else
        user if user.valid_password?(password)
      end
    end

    def log
      Gitlab::AppLogger
    end

    def ldap_conf
      @ldap_conf ||= Gitlab.config.ldap
    end
  end
end
