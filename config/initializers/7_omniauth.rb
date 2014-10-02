module OmniAuth::Strategies
  Gitlab.config.ldap.servers.each do |server|
    class_name = "Ldap#{server.index}"
    const_set(class_name, Class.new(LDAP))
  end
end
