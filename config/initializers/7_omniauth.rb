module OmniAuth::Strategies
  Gitlab.config.ldap.servers.each_with_index do |server|
    const_set(server.provider_class, Class.new(LDAP))
  end
end
