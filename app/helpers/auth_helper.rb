# frozen_string_literal: true

module AuthHelper
  PROVIDERS_WITH_ICONS = %w[
    alicloud
    atlassian_oauth2
    auth0
    azure_activedirectory_v2
    azure_oauth2
    bitbucket
    github
    gitlab
    google_oauth2
    jwt
    openid_connect
    shibboleth
    twitter
  ].freeze
  LDAP_PROVIDER = /\Aldap/
  POPULAR_PROVIDERS = %w[google_oauth2 github].freeze

  delegate :slack_app_id, to: :'Gitlab::CurrentSettings.current_application_settings'

  def ldap_enabled?
    Gitlab::Auth::Ldap::Config.enabled?
  end

  def ldap_sign_in_enabled?
    Gitlab::Auth::Ldap::Config.sign_in_enabled?
  end

  def omniauth_enabled?
    Gitlab::Auth.omniauth_enabled?
  end

  def enabled_button_based_providers_for_signup
    if Gitlab.config.omniauth.allow_single_sign_on.is_a?(Array)
      enabled_button_based_providers & Gitlab.config.omniauth.allow_single_sign_on
    elsif Gitlab.config.omniauth.allow_single_sign_on
      enabled_button_based_providers
    else
      []
    end
  end

  def signup_button_based_providers_enabled?
    omniauth_enabled? && enabled_button_based_providers_for_signup.any?
  end

  def provider_has_custom_icon?(name)
    icon_for_provider(name.to_s)
  end

  def provider_has_builtin_icon?(name)
    PROVIDERS_WITH_ICONS.include?(name.to_s)
  end

  def provider_has_icon?(name)
    provider_has_builtin_icon?(name) || provider_has_custom_icon?(name)
  end

  def test_id_for_provider(provider)
    {
      saml: 'saml-login-button',
      openid_connect: 'oidc-login-button',
      github: 'github-login-button',
      gitlab: 'gitlab-oauth-login-button'
    }[provider.to_sym]
  end

  def auth_providers
    Gitlab::Auth::OAuth::Provider.providers
  end

  def label_for_provider(name)
    Gitlab::Auth::OAuth::Provider.label_for(name)
  end

  def icon_for_provider(name)
    Gitlab::Auth::OAuth::Provider.icon_for(name)
  end

  def form_based_provider_priority
    ['crowd', /^ldap/]
  end

  def form_based_provider_with_highest_priority
    @form_based_provider_with_highest_priority ||= form_based_provider_priority.each do |provider_regexp|
      highest_priority = form_based_providers.find { |provider| provider.match?(provider_regexp) }
      break highest_priority unless highest_priority.nil?
    end
  end

  def form_based_auth_provider_has_active_class?(provider)
    form_based_provider_with_highest_priority == provider
  end

  def form_based_provider?(name)
    [LDAP_PROVIDER, 'crowd'].any? { |pattern| pattern === name.to_s }
  end

  def form_based_providers
    auth_providers.select { |provider| form_based_provider?(provider) }
  end

  def saml_providers
    providers = Gitlab.config.omniauth.providers.select do |provider|
      provider.name == 'saml' || provider.dig('args', 'strategy_class') == 'OmniAuth::Strategies::SAML'
    end

    providers.map(&:name).map(&:to_sym)
  end

  def oidc_providers
    providers = Gitlab.config.omniauth.providers.select do |provider|
      provider.name == 'openid_connect' || provider.dig('args',
        'strategy_class') == 'OmniAuth::Strategies::OpenIDConnect'
    end

    providers.map(&:name).map(&:to_sym)
  end

  def any_form_based_providers_enabled?
    form_based_providers.any? { |provider| form_enabled_for_sign_in?(provider) }
  end

  def form_enabled_for_sign_in?(provider)
    return true unless provider.to_s.match?(LDAP_PROVIDER)

    ldap_sign_in_enabled?
  end

  def crowd_enabled?
    auth_providers.include? :crowd
  end

  def button_based_providers
    auth_providers.reject { |provider| form_based_provider?(provider) }
  end

  def display_providers_on_profile?
    button_based_providers.any?
  end

  def providers_for_base_controller
    auth_providers.reject { |provider| LDAP_PROVIDER === provider }
  end

  def enabled_button_based_providers
    disabled_providers = Gitlab::CurrentSettings.disabled_oauth_sign_in_sources || []

    providers = button_based_providers.map(&:to_s) - disabled_providers
    providers.sort_by do |provider|
      POPULAR_PROVIDERS.index(provider) || POPULAR_PROVIDERS.length
    end
  end

  def popular_enabled_button_based_providers
    enabled_button_based_providers & POPULAR_PROVIDERS
  end

  def button_based_providers_enabled?
    enabled_button_based_providers.any?
  end

  def provider_image_tag(provider, size = 64)
    label = label_for_provider(provider)

    if provider_has_custom_icon?(provider)
      image_tag(icon_for_provider(provider), alt: label, title: "Sign in with #{label}", class: "gl-button-icon")
    elsif provider_has_builtin_icon?(provider)
      file_name = "#{provider.to_s.split('_').first}_#{size}.png"

      image_tag("auth_buttons/#{file_name}", alt: label, title: "Sign in with #{label}", class: "gl-button-icon")
    else
      label
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def auth_active?(provider)
    return current_user.atlassian_identity.present? if provider == :atlassian_oauth2

    current_user.identities.exists?(provider: provider.to_s)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def unlink_provider_allowed?(provider)
    IdentityProviderPolicy.new(current_user, provider).can?(:unlink)
  end

  def link_provider_allowed?(provider)
    IdentityProviderPolicy.new(current_user, provider).can?(:link)
  end

  def allow_admin_mode_password_authentication_for_web?
    current_user.allow_password_authentication_for_web? && !current_user.password_automatically_set?
  end

  def auth_app_owner_text(owner)
    return _('An administrator added this OAuth application ') unless owner

    if owner.is_a?(Group)
      group_link = link_to(owner.name, group_path(owner))
      safe_format(_("%{group_link} added this OAuth application "), group_link: group_link)
    else
      user_link = link_to(owner.name, user_path(owner))
      safe_format(_("%{user_link} added this OAuth application "), user_link: user_link)
    end
  end

  def delete_otp_authenticator_data(password_required)
    message = if password_required
                _('Are you sure you want to delete this one-time password authenticator? ' \
                  'Enter your password to continue.')
              else
                _('Are you sure you want to delete this one-time password authenticator?')
              end

    { button_text: _('Delete one-time password authenticator'),
      message: message,
      path: destroy_otp_profile_two_factor_auth_path,
      password_required: password_required.to_s }
  end

  def delete_webauthn_device_data(password_required, path)
    message = if password_required
                _('Are you sure you want to delete this WebAuthn device? ' \
                  'Enter your password to continue.')
              else
                _('Are you sure you want to delete this WebAuthn device?')
              end

    { button_text: _('Delete WebAuthn device'),
      icon: 'remove',
      message: message,
      path: path,
      password_required: password_required.to_s }
  end

  def disable_two_factor_authentication_data(password_required)
    message = if password_required
                _('Are you sure you want to invalidate your one-time password authenticator and WebAuthn devices? ' \
                  'Enter your password to continue. This action cannot be undone.')
              else
                _('Are you sure you want to invalidate your one-time password authenticator and WebAuthn devices?')
              end

    { button_text: _('Disable two-factor authentication'),
      message: message,
      path: profile_two_factor_auth_path,
      password_required: password_required.to_s }
  end

  def codes_two_factor_authentication_data(password_required)
    message = if password_required
                _('Are you sure you want to regenerate recovery codes? ' \
                  'Enter your password to continue.')
              else
                _('Are you sure you want to regenerate recovery codes?')
              end

    { button_text: _('Regenerate recovery codes'),
      message: message,
      method: 'post',
      path: codes_profile_two_factor_auth_path,
      password_required: password_required.to_s,
      variant: 'default' }
  end

  extend self
end

AuthHelper.prepend_mod_with('AuthHelper')

# The methods added in EE should be available as both class and instance
# methods, just like the methods provided by `AuthHelper` itself.
AuthHelper.extend_mod_with('AuthHelper')
