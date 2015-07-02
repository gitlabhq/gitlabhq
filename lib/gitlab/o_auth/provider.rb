module Gitlab
  module OAuth
    class Provider
      def self.providers
        Devise.omniauth_providers
      end

      def self.enabled?(name)
        providers.include?(name.to_sym)
      end

      def self.ldap_provider?(name)
        name.to_s.start_with?('ldap')
      end

      def self.config_for(name)
        name = name.to_s
        if ldap_provider?(name)
          Gitlab::LDAP::Config.new(name).options
        else
          Gitlab.config.omniauth.providers.find { |provider| provider.name == name }
        end
      end

      def self.label_for(name)
        config = config_for(name)
        (config && config['label']) || name.to_s.titleize
      end
    end
  end
end
