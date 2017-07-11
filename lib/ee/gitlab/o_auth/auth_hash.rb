module EE
  module Gitlab
    module OAuth
      module AuthHash
        def kerberos_default_realm
          ::Gitlab::Kerberos::Authentication.kerberos_default_realm
        end

        # For Kerberos, usernames `principal` and `principal@DEFAULT.REALM` are equivalent and
        # may be used indifferently, but omniauth_kerberos does not normalize them as of version 0.3.0.
        # Normalize here the uid to always have the canonical Kerberos principal name with realm.
        def kerberos_normalized_uid
          @kerberos_normalized_uid ||=
            begin
              uid = ::Gitlab::Utils.force_utf8(auth_hash.uid.to_s)
              uid += '@' + kerberos_default_realm unless uid.include?('@')
              uid
            end
        end

        def uid
          if provider == 'kerberos'
            kerberos_normalized_uid
          else
            super
          end
        end
      end
    end
  end
end
