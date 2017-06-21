if Gitlab::LDAP::Config.enabled?
  module OmniAuth::Strategies
    server = Gitlab.config.ldap.servers.values.first
    klass = server['provider_class']
    const_set(klass, Class.new(LDAP)) unless klass == 'LDAP'
  end

  OmniauthCallbacksController.class_eval do
    server = Gitlab.config.ldap.servers.values.first
    alias_method server['provider_name'], :ldap
  end
end

OmniAuth.config.full_host = Settings.gitlab['base_url']
OmniAuth.config.allowed_request_methods = [:post]
# In case of auto sign-in, the GET method is used (users don't get to click on a button)
OmniAuth.config.allowed_request_methods << :get if Gitlab.config.omniauth.auto_sign_in_with_provider.present?
OmniAuth.config.before_request_phase do |env|
  GitLab::RequestForgeryProtection.call(env)
end

if Gitlab.config.omniauth.enabled
  provider_names = Gitlab.config.omniauth.providers.map(&:name)
  require 'omniauth-kerberos' if provider_names.include?('kerberos')
end

module OmniAuth
  module Strategies
    autoload :Bitbucket, Rails.root.join('lib', 'omni_auth', 'strategies', 'bitbucket')
  end
end
