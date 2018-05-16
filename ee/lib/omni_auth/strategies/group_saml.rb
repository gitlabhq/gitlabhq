module OmniAuth
  module Strategies
    class GroupSaml < SAML
      option :name, 'group_saml'
      option :callback_path, ->(env) { callback?(env) }

      def setup_phase
        # Set devise scope for custom callback URL
        env["devise.mapping"] = Devise.mappings[:user]

        group_lookup = Gitlab::Auth::GroupSaml::GroupLookup.new(env)

        unless group_lookup.group_saml_enabled?
          raise ActionController::RoutingError, group_lookup.path
        end

        saml_provider = group_lookup.saml_provider
        dynamic_settings = Gitlab::Auth::GroupSaml::DynamicSettings.new(saml_provider)
        env['omniauth.strategy'].options.merge!(dynamic_settings.settings)

        super
      end

      def self.callback?(env)
        env['PATH_INFO'] =~ Gitlab::PathRegex.saml_callback_regex
      end
    end
  end
end
