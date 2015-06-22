module Gitlab
  module OAuth
    class Provider
      def self.names
        providers = []

        Gitlab.config.ldap.servers.values.each do |server|
          providers << server['provider_name']
        end

        Gitlab.config.omniauth.providers.each do |provider|
          providers << provider['name']
        end

        providers
      end
    end
  end
end
