module AuthHelper
  PROVIDERS_WITH_ICONS = %w(twitter github gitlab bitbucket google_oauth2 facebook azure_oauth2).freeze
  FORM_BASED_PROVIDERS = [/\Aldap/, 'kerberos', 'crowd'].freeze

  def ldap_enabled?
    Gitlab.config.ldap.enabled
  end

  def kerberos_enabled?
    auth_providers.include?(:kerberos)
  end

  def omniauth_enabled?
    Gitlab.config.omniauth.enabled
  end

  def provider_has_icon?(name)
    PROVIDERS_WITH_ICONS.include?(name.to_s)
  end

  def auth_providers
    Gitlab::OAuth::Provider.providers
  end

  def label_for_provider(name)
    Gitlab::OAuth::Provider.label_for(name)
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
    disabled_providers = current_application_settings.disabled_oauth_sign_in_sources || []

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

  def two_factor_skippable?
    current_application_settings.require_two_factor_authentication &&
      !current_user.two_factor_enabled? &&
      current_application_settings.two_factor_grace_period &&
      !two_factor_grace_period_expired?
  end

  def two_factor_grace_period_expired?
    current_user.otp_grace_period_started_at &&
      (current_user.otp_grace_period_started_at + current_application_settings.two_factor_grace_period.hours) < Time.current
  end

  extend self
end
