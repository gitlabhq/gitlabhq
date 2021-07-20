# frozen_string_literal: true

# Load a specific server configuration
module Gitlab
  module Auth
    module Ldap
      class Config
        NET_LDAP_ENCRYPTION_METHOD = {
          simple_tls: :simple_tls,
          start_tls:  :start_tls,
          plain:      nil
        }.freeze

        attr_accessor :provider, :options

        InvalidProvider = Class.new(StandardError)

        def self.enabled?
          Gitlab.config.ldap.enabled
        end

        def self.sign_in_enabled?
          enabled? && !prevent_ldap_sign_in?
        end

        def self.prevent_ldap_sign_in?
          Gitlab.config.ldap.prevent_ldap_sign_in
        end

        def self.servers
          Gitlab.config.ldap.servers&.values || []
        end

        def self.available_servers
          return [] unless enabled?

          _available_servers
        end

        def self._available_servers
          Array.wrap(servers.first)
        end

        def self.providers
          provider_names_from_servers(servers)
        end

        def self.available_providers
          provider_names_from_servers(available_servers)
        end

        def self.provider_names_from_servers(servers)
          servers&.map { |server| server['provider_name'] } || []
        end
        private_class_method :provider_names_from_servers

        def self.valid_provider?(provider)
          providers.include?(provider)
        end

        def self.invalid_provider(provider)
          raise InvalidProvider, "Unknown provider (#{provider}). Available providers: #{providers}"
        end

        def self.encrypted_secrets
          Settings.encrypted(Gitlab.config.ldap.secret_file)
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
            disable_verify_certificates: !options['verify_certificates'],
            tls_options: tls_options
          )

          if has_auth?
            opts.merge!(
              bind_dn: auth_username,
              password: auth_password
            )
          end

          opts
        end

        def base
          @base ||= Person.normalize_dn(options['base'])
        end

        def uid
          options['uid']
        end

        def label
          options['label']
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

        def retry_empty_result_with_codes
          options.fetch('retry_empty_result_with_codes', [])
        end

        def external_groups
          options['external_groups'] || []
        end

        def has_auth?
          auth_password || auth_username
        end

        def allow_username_or_email_login
          options['allow_username_or_email_login']
        end

        def lowercase_usernames
          options['lowercase_usernames']
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
            'username'    => %W(#{uid} uid sAMAccountName userid).uniq,
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
          method = translate_method
          return unless method

          {
            method: method,
            tls_options: tls_options
          }
        end

        def translate_method
          NET_LDAP_ENCRYPTION_METHOD[options['encryption']&.to_sym]
        end

        def tls_options
          return @tls_options if defined?(@tls_options)

          method = translate_method
          return unless method

          opts = if options['verify_certificates'] && method != 'plain'
                   # Dup so we don't accidentally overwrite the constant
                   OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.dup
                 else
                   # It is important to explicitly set verify_mode for two reasons:
                   # 1. The behavior of OpenSSL is undefined when verify_mode is not set.
                   # 2. The net-ldap gem implementation verifies the certificate hostname
                   #    unless verify_mode is set to VERIFY_NONE.
                   { verify_mode: OpenSSL::SSL::VERIFY_NONE }
                 end

          opts.merge!(custom_tls_options)

          @tls_options = opts
        end

        def custom_tls_options
          return {} unless options['tls_options']

          # Dup so we don't overwrite the original value
          custom_options = options['tls_options'].dup.delete_if { |_, value| value.nil? || value.blank? }
          custom_options.symbolize_keys!

          if custom_options[:cert]
            begin
              custom_options[:cert] = OpenSSL::X509::Certificate.new(custom_options[:cert])
            rescue OpenSSL::X509::CertificateError => e
              Gitlab::AppLogger.error "LDAP TLS Options 'cert' is invalid for provider #{provider}: #{e.message}"
            end
          end

          if custom_options[:key]
            begin
              custom_options[:key] = OpenSSL::PKey.read(custom_options[:key])
            rescue OpenSSL::PKey::PKeyError => e
              Gitlab::AppLogger.error "LDAP TLS Options 'key' is invalid for provider #{provider}: #{e.message}"
            end
          end

          custom_options
        end

        def auth_options
          {
            auth: {
              method: :simple,
              username: auth_username,
              password: auth_password
            }
          }
        end

        def secrets
          @secrets ||= self.class.encrypted_secrets[@provider.delete_prefix('ldap').to_sym]
        rescue StandardError => e
          Gitlab::AppLogger.error "LDAP encrypted secrets are invalid: #{e.inspect}"

          nil
        end

        def auth_password
          return options['password'] if options['password']

          secrets&.fetch(:password, nil)&.chomp
        end

        def auth_username
          return options['bind_dn'] if options['bind_dn']

          secrets&.fetch(:bind_dn, nil)&.chomp
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
end

Gitlab::Auth::Ldap::Config.prepend_mod_with('Gitlab::Auth::Ldap::Config')
