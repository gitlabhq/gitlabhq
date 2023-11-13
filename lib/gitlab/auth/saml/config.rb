# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class Config
        class << self
          def enabled?
            ::AuthHelper.saml_providers.any?
          end

          def default_attribute_statements
            defaults = OmniAuth::Strategies::SAML.default_options[:attribute_statements].to_hash.deep_symbolize_keys
            defaults[:nickname] = %w[username nickname]
            defaults[:name] << 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'
            defaults[:name] << 'http://schemas.microsoft.com/ws/2008/06/identity/claims/name'
            defaults[:email] << 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
            defaults[:email] << 'http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress'
            defaults[:first_name] << 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'
            defaults[:first_name] << 'http://schemas.microsoft.com/ws/2008/06/identity/claims/givenname'
            defaults[:last_name] << 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'
            defaults[:last_name] << 'http://schemas.microsoft.com/ws/2008/06/identity/claims/surname'

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
