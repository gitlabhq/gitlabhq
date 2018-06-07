module EE
  module Gitlab
    module Auth
      extend ::Gitlab::Utils::Override

      override :omniauth_customized_providers
      def omniauth_customized_providers
        @omniauth_customized_providers ||=
          super.concat(%w[kerberos_spnego group_saml])
      end

      override :omniauth_setup_a_provider
      def omniauth_setup_a_provider(provider)
        super

        if provider == 'group_saml'
          OmniAuth.config.on_failure =
            ::Gitlab::Auth::GroupSaml::FailureHandler.new(
              OmniAuth.config.on_failure)
        end
      end

      override :find_with_user_password
      def find_with_user_password(login, password)
        if Devise.omniauth_providers.include?(:kerberos)
          kerberos_user = ::Gitlab::Kerberos::Authentication.login(login, password)
          return kerberos_user if kerberos_user
        end

        super
      end

      override :find_build_by_token
      def find_build_by_token(token)
        ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
          super
        end
      end
    end
  end
end
