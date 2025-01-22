# frozen_string_literal: true

# SAML extension for User model
#
# * Find GitLab user based on SAML uid and provider
# * Create new user from SAML data
#
module Gitlab
  module Auth
    module Saml
      class User < Gitlab::Auth::OAuth::User
        extend ::Gitlab::Utils::Override

        def find_user
          user = find_by_uid_and_provider

          user ||= find_by_email if auto_link_saml_user?
          user ||= find_or_build_ldap_user if auto_link_ldap_user?
          user ||= build_new_user if signup_enabled?

          user&.external = external_user? if any_external_config_present?

          user
        end

        override :should_save?
        def should_save?
          return true unless gl_user

          gl_user.changed? || gl_user.identities.any?(&:changed?)
        end

        def bypass_two_factor?
          saml_config.upstream_two_factor_authn_contexts&.include?(auth_hash.authn_context)
        end

        def protocol_name
          'SAML'
        end

        protected

        def saml_config
          Gitlab::Auth::Saml::Config.new(auth_hash.provider)
        end

        def auto_link_saml_user?
          Gitlab.config.omniauth.auto_link_saml_user
        end

        def external_users_enabled?
          !saml_config.external_groups.nil?
        end

        def any_external_config_present?
          external_provider? || external_users_enabled?
        end

        def auth_hash=(auth_hash)
          @auth_hash = Gitlab::Auth::Saml::AuthHash.new(auth_hash)
        end

        private

        def external_user?
          return true if external_provider?
          return intersecting_external_groups? if external_users_enabled?

          false
        end

        def intersecting_external_groups?
          !(auth_hash.groups & saml_config.external_groups).empty?
        end
      end
    end
  end
end

Gitlab::Auth::Saml::User.prepend_mod_with('Gitlab::Auth::Saml::User')
