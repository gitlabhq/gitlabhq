if Gitlab::LDAP::Config.enabled?
  module OmniAuth::Strategies
<<<<<<< HEAD
    Gitlab::LDAP::Config.servers.each do |server|
      # do not redeclare LDAP
      next if server['provider_name'] == 'ldap'
      const_set(server['provider_class'], Class.new(LDAP))
    end
=======
    server = Gitlab.config.ldap.servers.values.first
    klass = server['provider_class']
    const_set(klass, Class.new(LDAP)) unless klass == 'LDAP'
>>>>>>> 7-4-stable
  end

  OmniauthCallbacksController.class_eval do
    Gitlab::LDAP::Config.servers.each do |server|
      alias_method server['provider_name'], :ldap
    end
  end
end