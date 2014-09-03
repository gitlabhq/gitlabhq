require 'gitlab/oauth/user'

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
        def find_or_create(auth)
          self.auth = auth
          find(auth) || create(auth)
        end

        # overloaded from Gitlab::Oauth::User
        # TODO: it's messy, needs cleanup, less complexity
        def create(auth)
          ldap_user = new(auth)
          # first try to find the user based on the returned email address
          user = ldap_user.find_gitlab_user_by_email

          if user
            user.update_attributes(extern_uid: ldap_user.uid, provider: ldap_user.provider)
            Gitlab::AppLogger.info("(LDAP) Updating legacy LDAP user #{ldap_user.email} with extern_uid => #{ldap_user.uid}")
            return user
          end

          # if the user isn't found by an exact email match, use oauth methods
          ldap_user.save_and_trigger_callbacks
        end

        def authenticate(login, password)
          # Check user against LDAP backend if user is not authenticated
          # Only check with valid login and password to prevent anonymous bind results
          return nil unless ldap_conf.enabled && login.present? && password.present?

          ldap = OmniAuth::LDAP::Adaptor.new(ldap_conf)
          filter = Net::LDAP::Filter.eq(ldap.uid, login)

          # Apply LDAP user filter if present
          if ldap_conf['user_filter'].present?
            user_filter = Net::LDAP::Filter.construct(ldap_conf['user_filter'])
            filter = Net::LDAP::Filter.join(filter, user_filter)
          end

          ldap_user = ldap.bind_as(
            filter: filter,
            size: 1,
            password: password
          )

          find_by_uid(ldap_user.dn) if ldap_user
        end

        protected

        def find_by_uid_and_provider
          find_by_uid(uid)
        end

        def find_by_uid(uid)
          # LDAP distinguished name is case-insensitive
          model.where("provider = ? and lower(extern_uid) = ?", provider, uid.downcase).last
        end

        def provider
          'ldap'
        end

        def raise_error(message)
          raise OmniAuth::Error, "(LDAP) " + message
        end

        def ldap_conf
          Gitlab.config.ldap
        end
      end

      def find_gitlab_user_by_email
        self.class.model.find_by(email: email)
      end

      def needs_blocking?
        false
      end
    end
  end
end
