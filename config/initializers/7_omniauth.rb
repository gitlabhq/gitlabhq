module OmniAuth::Strategies
  Gitlab.config.ldap.servers.each_with_index do |server|
    next unless server.provider_id.present?
    const_set(server.provider_class, Class.new(LDAP))
  end
end

OmniauthCallbacksController.class_eval do
  Gitlab.config.ldap.servers.each do |server|
    alias_method server.provider_name, :ldap
  end
end
