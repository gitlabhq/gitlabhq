module Gitlab
  module UserAccess
    def self.allowed?(user)
      return false if user.blocked?

      if Gitlab.config.ldap.enabled
        if user.ldap_user?
          # Check if LDAP user exists and match LDAP user_filter
          Gitlab::LDAP::Access.open do |adapter|
            return false unless adapter.allowed?(user)
          end
        end
      end

      true
    end
  end
end
