module OmniAuth::Strategies
  server = Gitlab.config.ldap.servers.first
  const_set(server.provider_class, Class.new(LDAP))
end

OmniauthCallbacksController.class_eval do
  server = Gitlab.config.ldap.servers.first
  alias_method server.provider_name, :ldap
end