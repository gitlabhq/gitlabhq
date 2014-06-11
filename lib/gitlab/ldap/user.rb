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
          @auth = auth

          if uid.blank? || email.blank? || username.blank?
            raise_error("Account must provide a dn, uid and email address")
          end

          user = find(auth)

          unless user
            # Look for user with same emails
            #
            # Possible cases:
            # * When user already has account and need to link their LDAP account.
            # * LDAP uid changed for user with same email and we need to update their uid
            #
            user = find_user(email)

            if user
              user.update_attributes(extern_uid: uid, provider: provider)
              log.info("(LDAP) Updating legacy LDAP user #{email} with extern_uid => #{uid}")
            else
              # Create a new user inside GitLab database
              # based on LDAP credentials
              #
              #
              user = create(auth)
            end
          end

          user
        end

        def find_user(email)
          user = model.find_by(email: email)

          # If no user found and allow_username_or_email_login is true
          # we look for user by extracting part of their email
          if !user && email && ldap_conf['allow_username_or_email_login']
            uname = email.partition('@').first
            # Strip apostrophes since they are disallowed as part of username
            username = uname.gsub("'", "")
            user = model.find_by(username: username)
          end

          user
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

        private

        def find_by_uid_and_provider
          find_by_uid(uid)
        end

        def find_by_uid(uid)
          # LDAP distinguished name is case-insensitive
          model.where("provider = ? and lower(extern_uid) = ?", provider, uid.downcase).last
        end

        def username
          auth.info.nickname.to_s.force_encoding("utf-8")
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
    end
  end
end
