# Load a specific server configuration
module Gitlab
  module LDAP
    class Config
      attr_accessor :provider, :options

      def initialize(provider)
        @provider = provider
        @options = config_for(provider)
      end

      def enabled?
        base_config.enabled
      end

      def adapter_options
        {
          host: options['host'],
          port: options['port'],
          encryption: encryption
        }.tap do |options|
          options.merge!(auth_options) if has_auth?
        end
      end

      def sync_ssh_keys?
        ssh_sync_key.present?
      end

      def ssh_sync_key
        options['sync_ssh_keys']
      end

      def user_filter
        options['user_filter']
      end

      def group_base
        options['group_base']
      end

      def admin_group
        options['admin_group']
      end

      protected
      def base_config
        Gitlab.config.ldap
      end

      def config_for(provider)
        base_config.servers.find { |server| server.provider_name == provider }
      end

      def encryption
        case options['method'].to_s
        when 'ssl'
          :simple_tls
        when 'tls'
          :start_tls
        else
          nil
        end
      end

      def auth_options
        {
          auth: {
            method: :simple,
            username: options['bind_dn'],
            password: options['password']
          }
        }
      end

      def has_auth?
        options['password'] || options['bind_dn']
      end
    end
  end
end
