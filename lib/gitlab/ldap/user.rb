require 'gitlab/o_auth/user'

# LDAP extension for User model
#
# * Find or create user from omniauth.auth data
# * Links LDAP account with existing user
# * Auth LDAP user with login and password
#
module Gitlab
  module LDAP
    class User < Gitlab::OAuth::User
      class << self
        def find_by_uid_and_provider(uid, provider)
          # LDAP distinguished name is case-insensitive
          identity = ::Identity.
            where(provider: provider).
            iwhere(extern_uid: uid).last
          identity && identity.user
        end
      end

      def initialize(auth_hash)
        super
        update_user_attributes
      end

      def save
        super('LDAP')
      end

      # instance methods
      def gl_user
        @gl_user ||= find_by_uid_and_provider || find_by_email || build_new_user
      end

      def find_by_uid_and_provider
        self.class.find_by_uid_and_provider(auth_hash.uid, auth_hash.provider)
      end

      def find_by_email
        ::User.find_by(email: auth_hash.email.downcase) if auth_hash.has_email?
      end

      def update_user_attributes
        if persisted?
          if auth_hash.has_email?
            gl_user.skip_reconfirmation!
            gl_user.email = auth_hash.email
          end

          # find_or_initialize_by doesn't update `gl_user.identities`, and isn't autosaved.
          identity = gl_user.identities.find { |identity|  identity.provider == auth_hash.provider }
          identity ||= gl_user.identities.build(provider: auth_hash.provider)

          # For a new identity set extern_uid to the LDAP DN
          # For an existing identity with matching email but changed DN, update the DN.
          # For an existing identity with no change in DN, this line changes nothing.
          identity.extern_uid = auth_hash.uid
        end

        gl_user.ldap_email = auth_hash.has_email?

        gl_user
      end

      def changed?
        gl_user.changed? || gl_user.identities.any?(&:changed?)
      end

      def block_after_signup?
        ldap_config.block_auto_created_users
      end

      def allowed?
        Gitlab::LDAP::Access.allowed?(gl_user)
      end

      def ldap_config
        Gitlab::LDAP::Config.new(auth_hash.provider)
      end

      def auth_hash=(auth_hash)
        @auth_hash = Gitlab::LDAP::AuthHash.new(auth_hash)
      end
    end
  end
end
