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
        if auto_link_ldap_user?
          @user ||= find_or_create_ldap_user
        end

        @user ||= find_by_uid_and_provider

        if auto_link_saml_user?
          @user ||= find_by_email
        end

        if signup_enabled?
          @user ||= build_new_user
        end

        if external_users_enabled? && @user
          # Check if there is overlap between the user's groups and the external groups
          # setting then set user as external or internal.
          if (auth_hash.groups & Gitlab::Saml::Config.external_groups).empty?
            @user.external = false
          else
            @user.external = true
          end
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

      def find_or_create_ldap_user
        return unless ldap_person

        # If a corresponding person exists with same uid in a LDAP server,
        # check if the user already has a GitLab account
        user = Gitlab::LDAP::User.find_by_uid_and_provider(ldap_person.dn, ldap_person.provider)
        if user
          # Case when a LDAP user already exists in Gitlab. Add the SAML identity to existing account.
          user.identities.build(extern_uid: auth_hash.uid, provider: auth_hash.provider)
        else
          # No account found using LDAP in Gitlab yet: check if there is a SAML account with
          # the passed uid and provider
          user = find_by_uid_and_provider
          if user.nil?
            # No SAML account found, build a new user.
            user = build_new_user
          end
          # Correct account is present, add the LDAP Identity to the user.
          user.identities.new(provider: ldap_person.provider, extern_uid: ldap_person.dn)
        end

        user
      end

      def auth_hash=(auth_hash)
        @auth_hash = Gitlab::Saml::AuthHash.new(auth_hash)
      end
    end
  end
end
