# Load a specific server configuration
module Gitlab
  module LDAP
    class Config
      NET_LDAP_ENCRYPTION_METHOD = {
        simple_tls: :simple_tls,
        start_tls:  :start_tls,
        plain:      nil
      }.freeze

      attr_accessor :provider, :options

      def self.enabled?
        Gitlab.config.ldap.enabled
      end

      def self.servers
        Gitlab.config.ldap['servers']&.values || []
      end

      def self.available_servers
        return [] unless enabled?

        Array.wrap(servers.first)
      end

      def self.providers
        servers.map { |server| server['provider_name'] }
      end

      def self.valid_provider?(provider)
        providers.include?(provider)
      end

      def self.invalid_provider(provider)
        raise "Unknown provider (#{provider}). Available providers: #{providers}"
      end

      def initialize(provider)
        if self.class.valid_provider?(provider)
          @provider = provider
        else
          self.class.invalid_provider(provider)
        end
        @options = config_for(@provider) # Use @provider, not provider
      end

      def enabled?
        base_config.enabled
      end

      def adapter_options
        opts = base_options.merge(
          encryption: encryption_options
        )

        opts.merge!(auth_options) if has_auth?

        opts
      end

      def omniauth_options
        opts = base_options.merge(
          base: base,
          encryption: options['encryption'],
          filter: omniauth_user_filter,
          name_proc: name_proc,
          disable_verify_certificates: !options['verify_certificates']
        )

        if has_auth?
          opts.merge!(
            bind_dn: options['bind_dn'],
            password: options['password']
          )
        end

        opts[:ca_file] = options['ca_file'] if options['ca_file'].present?
        opts[:ssl_version] = options['ssl_version'] if options['ssl_version'].present?

        opts
      end

      def base
        options['base']
      end

      def uid
        options['uid']
      end

      def sync_ssh_keys?
        sync_ssh_keys.present?
      end

      # The LDAP attribute in which the ssh keys are stored
      def sync_ssh_keys
        options['sync_ssh_keys']
      end

      def user_filter
        options['user_filter']
      end

      def constructed_user_filter
        @constructed_user_filter ||= Net::LDAP::Filter.construct(user_filter)
      end

      def group_base
        options['group_base']
      end

      def admin_group
        options['admin_group']
      end

      def active_directory
        options['active_directory']
      end

      def block_auto_created_users
        options['block_auto_created_users']
      end

      def attributes
        default_attributes.merge(options['attributes'])
      end

      def timeout
        options['timeout'].to_i
      end

      def has_auth?
        options['password'] || options['bind_dn']
      end

      def allow_username_or_email_login
        options['allow_username_or_email_login']
      end

      def name_proc
        if allow_username_or_email_login
          proc { |name| name.gsub(/@.*\z/, '') }
        else
          proc { |name| name }
        end
      end

      def default_attributes
        {
          'username'    => %w(uid sAMAccountName userid),
          'email'       => %w(mail email userPrincipalName),
          'name'        => 'cn',
          'first_name'  => 'givenName',
          'last_name'   => 'sn'
        }
      end

      protected

      def base_options
        {
          host: options['host'],
          port: options['port']
        }
      end

      def base_config
        Gitlab.config.ldap
      end

      def config_for(provider)
        base_config.servers.values.find { |server| server['provider_name'] == provider }
      end

      def encryption_options
        method = translate_method(options['encryption'])
        return nil unless method

        {
          method: method,
          tls_options: tls_options(method)
        }
      end

      def translate_method(method_from_config)
        NET_LDAP_ENCRYPTION_METHOD[method_from_config.to_sym]
      end

      def tls_options(method)
        return { verify_mode: OpenSSL::SSL::VERIFY_NONE } unless method

        opts = if options['verify_certificates']
                 OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
               else
                 # It is important to explicitly set verify_mode for two reasons:
                 # 1. The behavior of OpenSSL is undefined when verify_mode is not set.
                 # 2. The net-ldap gem implementation verifies the certificate hostname
                 #    unless verify_mode is set to VERIFY_NONE.
                 { verify_mode: OpenSSL::SSL::VERIFY_NONE }
               end

        opts[:ca_file] = options['ca_file'] if options['ca_file'].present?
        opts[:ssl_version] = options['ssl_version'] if options['ssl_version'].present?

        opts
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

      def omniauth_user_filter
        uid_filter = Net::LDAP::Filter.eq(uid, '%{username}')

        if user_filter.present?
          Net::LDAP::Filter.join(uid_filter, constructed_user_filter).to_s
        else
          uid_filter.to_s
        end
      end
    end
  end
end
