module EE
  module Gitlab
    module OAuth
      module User
        protected

        def find_ldap_person(auth_hash, adapter)
          if auth_hash.provider == 'kerberos'
            ::Gitlab::LDAP::Person.find_by_kerberos_principal(auth_hash.uid, adapter)
          else
            super
          end
        end
      end
    end
  end
end
