module EE
  module Gitlab
    module OAuth
      module AuthHash
        def kerberos_default_realm
          ::Gitlab::Kerberos::Authentication.kerberos_default_realm
        end

        def uid
          return @ee_uid if defined?(@ee_uid)

          ee_uid = super

          # For Kerberos, usernames `principal` and `principal@DEFAULT.REALM`
          # are equivalent and may be used indifferently, but omniauth_kerberos
          # does not normalize them as of version 0.3.0, so add the default
          # realm ourselves if appropriate
          if provider == 'kerberos' && ee_uid.present?
            ee_uid += "@#{kerberos_default_realm}" unless ee_uid.include?('@')
          end

          @ee_uid = ee_uid
        end
      end
    end
  end
end
