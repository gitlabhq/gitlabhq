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

      def gl_user
        @user ||= find_by_uid_and_provider

        if auto_link_ldap_user?
          @user ||= find_or_create_ldap_user
        end

        if auto_link_saml_enabled?
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

      protected

      def auto_link_saml_enabled?
        Gitlab.config.omniauth.auto_link_saml_user
      end
    end
  end
end
