module EE
  module Gitlab
    module Auth
      def find_with_user_password(login, password)
        if Devise.omniauth_providers.include?(:kerberos)
          kerberos_user = ::Gitlab::Kerberos::Authentication.login(login, password)
          return kerberos_user if kerberos_user
        end

        super
      end
    end
  end
end
