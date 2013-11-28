require 'gitlab/oauth/user'

# PAM extension for User model
#
# * Find or create user from omniauth.auth data
# * Links PAM account with existing user
# * Auth PAM user with login and password
#
module Gitlab
  module PAM
    class User < Gitlab::OAuth::User
      class << self
        def find_or_create(auth)
          @auth = auth

          if uid.blank? || email.blank?
            raise_error("Account must provide an uid and email address")
          end

          user = find(auth)

          unless user
            # Look for user with same emails
            #
            # Possible cases:
            # * When user already has account and need to link his PAM account.
            # * PAM uid changed for user with same email and we need to update his uid
            #
            user = model.find_by_email(email)

            if user
              user.update_attributes(extern_uid: uid, provider: provider)
              log.info("(PAM) Updating legacy PAM user #{email} with extern_uid => #{uid}")
            else
              # Create a new user inside GitLab database
              # based on PAM credentials
              #
              #
              user = create(auth)
            end
          end

          user
        end

        def authenticate(login, password)
          # Check user against PAM backend if user is not authenticated
          # Only check with valid login and password to prevent anonymous bind results
          return nil unless pam_conf.enabled && login.present? && password.present?

          # Keep updated by https://github.com/nickcharlton/omniauth-pam/blob/master/lib/omniauth/strategies/pam.rb
          rpam_opts = Hash.new
          rpam_opts[:service] = pam_conf[:service] unless pam_conf[:service].nil?
          return find_by_uid(login) if Rpam.auth(login, password, rpam_opts)
        end

        private

        def find_by_uid(uid)
          model.where(provider: provider, extern_uid: uid).last
        end

        def provider
          'pam'
        end

        def raise_error(message)
          raise OmniAuth::Error, "(PAM) " + message
        end

        def pam_conf
          Gitlab.config.pam
        end
      end
    end
  end
end
