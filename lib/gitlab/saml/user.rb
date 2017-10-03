# SAML extension for User model
#
# * Find GitLab user based on SAML uid and provider
# * Create new user from SAML data
#
module Gitlab
  module Saml
    class User < Gitlab::OAuth::User
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
          user.external = !(auth_hash.groups & Gitlab::Saml::Config.external_groups).empty?
        end

<<<<<<< HEAD
        if admin_groups_enabled? && @user
          @user.admin =
            if (auth_hash.groups & Gitlab::Saml::Config.admin_groups).empty?
              false
            else
              true
            end
        end

        @user
      end

      def find_by_email
        if auth_hash.has_attribute?(:email)
          user = ::User.find_by(email: auth_hash.email.downcase)
          user.identities.new(extern_uid: auth_hash.uid, provider: auth_hash.provider) if user
          user
        end
=======
        user
>>>>>>> bdc50ed779cb0c7d266c0f80f3e66a25da8b1964
      end

      def changed?
        return true unless gl_user
        gl_user.changed? || gl_user.identities.any?(&:changed?)
      end

      protected

      def auto_link_saml_user?
        Gitlab.config.omniauth.auto_link_saml_user
      end

      def external_users_enabled?
        !Gitlab::Saml::Config.external_groups.nil?
      end

      def auth_hash=(auth_hash)
        @auth_hash = Gitlab::Saml::AuthHash.new(auth_hash)
      end

      def admin_groups_enabled?
        !Gitlab::Saml::Config.admin_groups.nil?
      end
    end
  end
end
