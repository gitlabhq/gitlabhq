module EE
  module Gitlab
    module OmniauthInitializer
      extend ::Gitlab::Utils::Override

      override :build_omniauth_customized_providers
      def build_omniauth_customized_providers
        super.concat(%i[kerberos_spnego group_saml])
      end

      override :setup_provider
      def setup_provider(provider)
        super

        if provider == :group_saml
          OmniAuth.config.on_failure =
            ::Gitlab::Auth::GroupSaml::FailureHandler.new(
              OmniAuth.config.on_failure)
        end
      end
    end
  end
end
