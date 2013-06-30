require 'omniauth-ldap'

module Grack
  module LDAP
    def ldap_auth(login, password)
      # Check user against LDAP backend if user is not authenticated
      # Only check with valid login and password to prevent anonymous bind results
      return nil unless ldap_conf.enabled && !login.blank? && !password.blank?

      ldap = OmniAuth::LDAP::Adaptor.new(ldap_conf)
      ldap_user = ldap.bind_as(
        filter: Net::LDAP::Filter.eq(ldap.uid, login),
        size: 1,
        password: password
      )

      User.find_by_extern_uid_and_provider(ldap_user.dn, 'ldap') if ldap_user
    end

    def ldap_conf
      @ldap_conf ||= Gitlab.config.ldap
    end
  end
end
