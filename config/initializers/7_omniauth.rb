if Gitlab::LDAP::Config.enabled?
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
end