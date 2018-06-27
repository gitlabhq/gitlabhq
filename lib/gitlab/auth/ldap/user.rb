# LDAP extension for User model
#
# * Find or create user from omniauth.auth data
# * Links LDAP account with existing user
# * Auth LDAP user with login and password
#
module Gitlab
  module Auth
    module LDAP
      class User < Gitlab::Auth::OAuth::User
        extend ::Gitlab::Utils::Override

        class << self
          def find_by_uid_and_provider(uid, provider)
            identity = ::Identity.with_extern_uid(provider, uid).take

            identity && identity.user
          end
        end

        def save
          super('LDAP')
        end

        # instance methods
        def find_user
          find_by_uid_and_provider || find_by_email || build_new_user
        end

        def find_by_uid_and_provider
          self.class.find_by_uid_and_provider(auth_hash.uid, auth_hash.provider)
        end

        override :should_save?
        def should_save?
          gl_user.changed? || gl_user.identities.any?(&:changed?)
        end

        def block_after_signup?
          ldap_config.block_auto_created_users
        end

        def allowed?
          Gitlab::Auth::LDAP::Access.allowed?(gl_user)
        end

        def valid_sign_in?
          allowed? && super
        end

        def ldap_config
          Gitlab::Auth::LDAP::Config.new(auth_hash.provider)
        end

        def auth_hash=(auth_hash)
          @auth_hash = Gitlab::Auth::LDAP::AuthHash.new(auth_hash)
        end
      end
    end
  end
end
