module Gitlab
  module LDAP
    class Access
      def allowed?(user)
        !!Gitlab::LDAP::Person.find_by_dn(user.extern_uid)
      rescue
        false
      end
    end
  end
end
