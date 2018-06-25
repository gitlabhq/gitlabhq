module EE
  module AuthHelper
    extend ::Gitlab::Utils::Override

    GROUP_LEVEL_PROVIDERS = %i(group_saml).freeze

    delegate :slack_app_id, to: :'Gitlab::CurrentSettings.current_application_settings'

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

    def kerberos_enabled?
      auth_providers.include?(:kerberos)
    end

    def slack_redirect_uri(project)
      slack_auth_project_settings_slack_url(project)
    end
  end
end
