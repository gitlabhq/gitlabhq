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

OmniAuth.config.full_host = Gitlab::OmniauthInitializer.full_host

OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.request_validation_phase do |env|
  Gitlab::RequestForgeryProtection.call(env)
end

OmniAuth.config.logger = Gitlab::AppLogger

omniauth_login_counter =
  Gitlab::Metrics.counter(
    :gitlab_omniauth_login_total,
    'Counter of initiated OmniAuth login attempts')

OmniAuth.config.before_request_phase do |env|
  provider = env['omniauth.strategy']&.name
  omniauth_login_counter.increment(omniauth_provider: provider, status: 'initiated')
end
