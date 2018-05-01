module EE
  module AuthHelper
    extend ::Gitlab::Utils::Override

    GROUP_LEVEL_PROVIDERS = %i(group_saml).freeze

    override :button_based_providers
    def button_based_providers
      super - GROUP_LEVEL_PROVIDERS
    end

    override :providers_for_base_controller
    def providers_for_base_controller
      super - GROUP_LEVEL_PROVIDERS
    end

    override :form_based_provider?
    def form_based_provider?(name)
      super || name.to_s == 'kerberos'
    end
  end
end
