# frozen_string_literal: true

# LDAP extension for User model
#
# * Find or create user from omniauth.auth data
# * Links LDAP account with existing user
# * Auth LDAP user with login and password
#
module Gitlab
  module Auth
    module Ldap
      class User < Gitlab::Auth::OAuth::User
        extend ::Gitlab::Utils::Override

        # instance methods
        def find_user
          find_by_uid_and_provider || find_by_email || build_new_user
        end

        override :should_save?
        def should_save?
          gl_user.changed? || gl_user.identities.any?(&:changed?)
        end

        def block_after_signup?
          ldap_config.block_auto_created_users
        end

        def allowed?
          Gitlab::Auth::Ldap::Access.allowed?(gl_user)
        end

        def valid_sign_in?
          # The order is important here: we need to ensure the
          # associated GitLab user entry is valid and persisted in the
          # database. Otherwise, the LDAP access check will fail since
          # the user doesn't have an associated LDAP identity.
          super && allowed?
        end

        def ldap_config
          Gitlab::Auth::Ldap::Config.new(auth_hash.provider)
        end

        def auth_hash=(auth_hash)
          @auth_hash = Gitlab::Auth::Ldap::AuthHash.new(auth_hash)
        end

        def protocol_name
          'LDAP'
        end
      end
    end
  end
end

Gitlab::Auth::Ldap::User.prepend_mod_with('Gitlab::Auth::Ldap::User')
