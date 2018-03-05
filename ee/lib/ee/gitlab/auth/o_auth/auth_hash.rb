module EE
  module Gitlab
    module Auth
      module OAuth
        module AuthHash
          include ::Gitlab::Utils::StrongMemoize

          def kerberos_default_realm
            ::Gitlab::Kerberos::Authentication.kerberos_default_realm
          end

          def uid
            strong_memoize(:ee_uid) do
              ee_uid = super

              # For Kerberos, usernames `principal` and `principal@DEFAULT.REALM`
              # are equivalent and may be used indifferently, but omniauth_kerberos
              # does not normalize them as of version 0.3.0, so add the default
              # realm ourselves if appropriate
              if provider == 'kerberos' && ee_uid.present?
                ee_uid += "@#{kerberos_default_realm}" unless ee_uid.include?('@')
              end

              ee_uid
            end
          end
        end
      end
    end
  end
end
