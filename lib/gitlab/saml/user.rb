# SAML extension for User model
#
# * Find GitLab user based on SAML uid and provider
# * Create new user from SAML data
#
module Gitlab
  module Saml
    class User < Gitlab::OAuth::User

      def initialize(auth_hash)
        super
        update_user_attributes
      end

      def save
        super('SAML')
      end

      def gl_user
        @user ||= find_by_uid_and_provider

        if auto_link_ldap_user?
          @user ||= find_or_create_ldap_user
        end

        if auto_link_saml_user?
          @user ||= find_by_email
        end

        if signup_enabled?
          @user ||= build_new_user
        end

        @user
      end

      def find_by_email
        if auth_hash.has_email?
          user = ::User.find_by(email: auth_hash.email.downcase)
          user.identities.new(extern_uid: auth_hash.uid, provider: auth_hash.provider) if user
          user
        end
      end

      def changed?
        gl_user.changed? || gl_user.identities.any?(&:changed?)
      end

      protected

      def build_new_user
        user = super
        if external_users_enabled?
          unless (auth_hash.groups & Gitlab::Saml::Config.external_groups).empty?
            user.external = true
          end
        end
        user
      end

      def auto_link_saml_user?
        Gitlab.config.omniauth.auto_link_saml_user
      end

      def external_users_enabled?
        !Gitlab::Saml::Config.external_groups.nil?
      end

      def auth_hash=(auth_hash)
        @auth_hash = Gitlab::Saml::AuthHash.new(auth_hash)
      end

      def update_user_attributes
        if persisted?
          if external_users_enabled?
            if (auth_hash.groups & Gitlab::Saml::Config.external_groups).empty?
              gl_user.external = false
            else
              gl_user.external = true
            end
          end
        end
      end
    end
  end
end
