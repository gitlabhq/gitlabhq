module AuthHelper
  PROVIDERS_WITH_ICONS = %w(twitter github gitlab bitbucket google_oauth2 facebook azure_oauth2 authentiq).freeze
  FORM_BASED_PROVIDERS = [/\Aldap/, 'crowd'].freeze

  def ldap_enabled?
    Gitlab::Auth::LDAP::Config.enabled?
  end

  def omniauth_enabled?
    Gitlab.config.omniauth.enabled
  end

  def provider_has_icon?(name)
    PROVIDERS_WITH_ICONS.include?(name.to_s)
  end

  def auth_providers
    Gitlab::Auth::OAuth::Provider.providers
  end

  def label_for_provider(name)
    Gitlab::Auth::OAuth::Provider.label_for(name)
  end

  def form_based_provider?(name)
    FORM_BASED_PROVIDERS.any? { |pattern| pattern === name.to_s }
  end

  def form_based_providers
    auth_providers.select { |provider| form_based_provider?(provider) }
  end

  def crowd_enabled?
    auth_providers.include? :crowd
  end

  def button_based_providers
    auth_providers.reject { |provider| form_based_provider?(provider) }
  end

  def enabled_button_based_providers
    disabled_providers = Gitlab::CurrentSettings.disabled_oauth_sign_in_sources || []

    button_based_providers.map(&:to_s) - disabled_providers
  end

  def button_based_providers_enabled?
    enabled_button_based_providers.any?
  end

  def provider_image_tag(provider, size = 64)
    label = label_for_provider(provider)

    if provider_has_icon?(provider)
      file_name = "#{provider.to_s.split('_').first}_#{size}.png"

      image_tag("auth_buttons/#{file_name}", alt: label, title: "Sign in with #{label}")
    else
      label
    end
  end

  def auth_active?(provider)
    current_user.identities.exists?(provider: provider.to_s)
  end

  def unlink_allowed?(provider)
    %w(saml cas3).exclude?(provider.to_s)
  end

  extend self
end
