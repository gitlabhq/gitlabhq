# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class Config
        DEFAULT_NICKNAME_ATTRS = %w[
          username
          nickname
          urn:oid:0.9.2342.19200300.100.1.1
        ].freeze
        DEFAULT_NAME_ATTRS = %w[
          http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name
          http://schemas.microsoft.com/ws/2008/06/identity/claims/name
          urn:oid:2.16.840.1.113730.3.1.241
          urn:oid:2.5.4.3
        ].freeze
        DEFAULT_EMAIL_ATTRS = %w[
          http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
          http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress
          http://schemas.xmlsoap.org/ws/2005/05/identity/claims/email
          http://schemas.microsoft.com/ws/2008/06/identity/claims/email
          urn:oid:0.9.2342.19200300.100.1.3
        ].freeze
        DEFAULT_FIRST_NAME_ATTRS = %w[
          http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname
          http://schemas.microsoft.com/ws/2008/06/identity/claims/givenname
          urn:oid:2.5.4.42
        ].freeze
        DEFAULT_LAST_NAME_ATTRS = %w[
          http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname
          http://schemas.microsoft.com/ws/2008/06/identity/claims/surname
          urn:oid:2.5.4.4
        ].freeze

        class << self
          def enabled?
            ::AuthHelper.saml_providers.any?
          end

          def default_attribute_statements
            defaults = OmniAuth::Strategies::SAML.default_options[:attribute_statements].to_hash.deep_symbolize_keys
            defaults[:nickname] = DEFAULT_NICKNAME_ATTRS.dup
            defaults[:name].concat(DEFAULT_NAME_ATTRS)
            defaults[:email].concat(DEFAULT_EMAIL_ATTRS)
            defaults[:first_name].concat(DEFAULT_FIRST_NAME_ATTRS)
            defaults[:last_name].concat(DEFAULT_LAST_NAME_ATTRS)

            defaults
          end
        end

        DEFAULT_PROVIDER_NAME = 'saml'

        def initialize(provider = DEFAULT_PROVIDER_NAME)
          @provider = provider
        end

        def options
          Gitlab::Auth::OAuth::Provider.config_for(@provider)
        end

        def upstream_two_factor_authn_contexts
          options.args[:upstream_two_factor_authn_contexts]
        end

        def groups
          options[:groups_attribute]
        end

        def external_groups
          options[:external_groups]
        end

        def admin_groups
          options[:admin_groups]
        end
      end
    end
  end
end

Gitlab::Auth::Saml::Config.prepend_mod_with('Gitlab::Auth::Saml::Config')
