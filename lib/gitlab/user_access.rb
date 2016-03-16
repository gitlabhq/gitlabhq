module Gitlab
  module UserAccess
    def self.allowed?(user)
      return false if user.blocked?

      if user.requires_ldap_check? && user.try_obtain_ldap_lease
        return false unless Gitlab::LDAP::Access.allowed?(user)
      end

      true
    end
  end
end
