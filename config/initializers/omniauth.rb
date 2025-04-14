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

OmniAuth.config.before_request_phase do |env|
  Gitlab::Auth::OAuth::BeforeRequestPhaseOauthLoginCounterIncrement.call(env)
  Gitlab::Auth::Oidc::StepUpAuthBeforeRequestPhase.call(env)
end
