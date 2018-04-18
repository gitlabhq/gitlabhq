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

          if user_in_required_group?
            unblock_user(user, "in required group") if user.persisted? && user.blocked?
          elsif user.persisted?
            block_user(user, "not in required group") unless user.blocked?
          else
            user = nil
          end

          if user
            user.external = !(auth_hash.groups & saml_config.external_groups).empty? if external_users_enabled?
            user.admin = !(auth_hash.groups & saml_config.admin_groups).empty? if admin_groups_enabled?
          end

          user
        end

        def changed?
          return true unless gl_user

          gl_user.changed? || gl_user.identities.any?(&:changed?)
        end

        override :omniauth_should_save?
        def omniauth_should_save?
          changed? && super
        end

        protected

        def saml_config
          Gitlab::Auth::Saml::Config
        end

        def block_user(user, reason)
          user.ldap_block
          log_user_changes(user, "#{reason}, blocking")
        end

        def unblock_user(user, reason)
          user.activate
          log_user_changes(user, "#{reason}, unblocking")
        end

        def log_user_changes(user, message)
          Gitlab::AppLogger.info(
            "SAML(#{auth_hash.provider}) account \"#{auth_hash.uid}\" #{message} " \
            "Gitlab user \"#{user.name}\" (#{user.email})"
          )
        end

        def user_in_required_group?
          required_groups = saml_config.required_groups
          required_groups.empty? || !(auth_hash.groups & required_groups).empty?
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

        def admin_groups_enabled?
          !saml_config.admin_groups.nil?
        end
      end
    end
  end
end
