module Gitlab
  module UserAccess
    def self.allowed?(user)
      return false if user.blocked?

      if user.requires_ldap_check? && Gitlab::LDAP::Access.try_lock_user(user)
          return Gitlab::LDAP::Access.allowed?(user)
        end
      end

      true
    end
  end
end
