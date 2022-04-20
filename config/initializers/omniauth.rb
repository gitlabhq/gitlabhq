# frozen_string_literal: true

if Gitlab::Auth::Ldap::Config.enabled?
  module OmniAuth::Strategies
    Gitlab::Auth::Ldap::Config.available_servers.each do |server|
      # do not redeclare LDAP
      next if server['provider_name'] == 'ldap'

      const_set(server['provider_class'], Class.new(LDAP))
    end
  end
end

OmniAuth.config.full_host =
  if Feature.feature_flags_available? && ::Feature.enabled?(:omniauth_initializer_fullhost_proc, default_enabled: :yaml)
    Gitlab::AppLogger.debug("Using OmniAuth proc initializer")
    Gitlab::OmniauthInitializer.full_host
  else
    Gitlab::AppLogger.debug("Fallback to OmniAuth static full_host")
    Settings.gitlab['base_url']
  end

OmniAuth.config.allowed_request_methods = [:post]
# In case of auto sign-in, the GET method is used (users don't get to click on a button)
OmniAuth.config.allowed_request_methods << :get if Gitlab.config.omniauth.auto_sign_in_with_provider.present?
OmniAuth.config.before_request_phase do |env|
  Gitlab::RequestForgeryProtection.call(env)
end

OmniAuth.config.logger = Gitlab::AppLogger
