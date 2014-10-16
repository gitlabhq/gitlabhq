<<<<<<< HEAD
module OmniAuth::Strategies
  Gitlab::LDAP::Config.servers.each do |server|
    # do not redeclare LDAP
    next if server['provider_name'] == 'ldap'
    const_set(server['provider_class'], Class.new(LDAP))
  end
end

OmniauthCallbacksController.class_eval do
  Gitlab::LDAP::Config.servers.each do |server|
    alias_method server['provider_name'], :ldap
  end
end
=======
if Gitlab::LDAP::Config.enabled?
  module OmniAuth::Strategies
    server = Gitlab.config.ldap.servers.values.first
    const_set(server['provider_class'], Class.new(LDAP))
  end

  OmniauthCallbacksController.class_eval do
    server = Gitlab.config.ldap.servers.values.first
    alias_method server['provider_name'], :ldap
  end
end
>>>>>>> d6fdca9a88356c9844e3597846044959bd765949
