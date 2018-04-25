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

        def save
          super('SAML')
        end

        def find_user
          user = find_by_uid_and_provider

          user ||= find_by_email if auto_link_saml_user?
          user ||= find_or_build_ldap_user if auto_link_ldap_user?
          user ||= build_new_user if signup_enabled?

          if external_users_enabled? && user
            # Check if there is overlap between the user's groups and the external groups
            # setting then set user as external or internal.
            user.external = !(auth_hash.groups & saml_config.external_groups).empty?
          end

          user
        end

        override :should_save?
        def should_save?
          return true unless gl_user

          gl_user.changed? || gl_user.identities.any?(&:changed?)
        end

        protected

        def saml_config
          Gitlab::Auth::Saml::Config
        end

        def auto_link_saml_user?
          Gitlab.config.omniauth.auto_link_saml_user
        end

        def external_users_enabled?
          !saml_config.external_groups.nil?
        end

        def auth_hash=(auth_hash)
          @auth_hash = Gitlab::Auth::Saml::AuthHash.new(auth_hash)
        end
      end
    end
  end
end
