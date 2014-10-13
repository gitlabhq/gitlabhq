module OmniAuth::Strategies
  server = Gitlab.config.ldap.servers.first
  const_set(server.provider_class, Class.new(LDAP))
end
