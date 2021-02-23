# frozen_string_literal: true

module Gitlab
  module Auth
    module OAuth
      class Provider
        LABELS = {
          "github"                   => "GitHub",
          "gitlab"                   => "GitLab.com",
          "google_oauth2"            => "Google",
          "azure_oauth2"             => "Azure AD",
          "azure_activedirectory_v2" => "Azure AD v2",
          'atlassian_oauth2'         => 'Atlassian'
        }.freeze

        def self.authentication(user, provider)
          return unless user
          return unless enabled?(provider)

          authenticator =
            case provider
            when /crowd/
              Gitlab::Auth::Crowd::Authentication
            when /^ldap/
              Gitlab::Auth::Ldap::Authentication
            when 'database'
              Gitlab::Auth::Database::Authentication
            end

          authenticator&.new(provider, user)
        end

        def self.providers
          Devise.omniauth_providers
        end

        def self.enabled?(name)
          return true if name == 'database'
          return true if self.ldap_provider?(name) && providers.include?(name.to_sym)

          Gitlab::Auth.omniauth_enabled? && providers.include?(name.to_sym)
        end

        def self.ldap_provider?(name)
          name.to_s.start_with?('ldap')
        end

        def self.sync_profile_from_provider?(provider)
          return true if ldap_provider?(provider)

          providers = Gitlab.config.omniauth.sync_profile_from_provider

          if providers.is_a?(Array)
            providers.include?(provider)
          else
            providers
          end
        end

        def self.config_for(name)
          name = name.to_s
          if ldap_provider?(name)
            if Gitlab::Auth::Ldap::Config.valid_provider?(name)
              Gitlab::Auth::Ldap::Config.new(name).options
            else
              nil
            end
          else
            provider = Gitlab.config.omniauth.providers.find { |provider| provider.name == name }
            merge_provider_args_with_defaults!(provider)

            provider
          end
        end

        def self.label_for(name)
          name = name.to_s
          config = config_for(name)
          (config && config['label']) || LABELS[name] || name.titleize
        end

        def self.icon_for(name)
          name = name.to_s
          config = config_for(name)
          config && config['icon']
        end

        def self.merge_provider_args_with_defaults!(provider)
          return unless provider

          provider['args'] ||= {}

          defaults = Gitlab::OmniauthInitializer.default_arguments_for(provider['name'])
          provider['args'].deep_merge!(defaults.deep_stringify_keys)
        end
      end
    end
  end
end
