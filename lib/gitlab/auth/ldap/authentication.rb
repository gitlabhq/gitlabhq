# frozen_string_literal: true

# These calls help to authenticate to LDAP by providing username and password
#
# Since multiple LDAP servers are supported, it will loop through all of them
# until a valid bind is found
#

module Gitlab
  module Auth
    module Ldap
      class Authentication < Gitlab::Auth::OAuth::Authentication
        def self.login(login, password)
          return unless Gitlab::Auth::Ldap::Config.enabled?
          return unless login.present? && password.present?

          # return found user that was authenticated by first provider for given login credentials
          providers.find do |provider|
            auth = new(provider)
            break auth.user if auth.login(login, password) # true will exit the loop
          end
        end

        def self.providers
          Gitlab::Auth::Ldap::Config.providers
        end

        def login(login, password)
          result = adapter.bind_as(
            filter: user_filter(login),
            size: 1,
            password: password
          )
          return unless result

          @user = Gitlab::Auth::Ldap::User.find_by_uid_and_provider(result.dn, provider)
        end

        def adapter
          OmniAuth::LDAP::Adaptor.new(config.omniauth_options)
        end

        def config
          Gitlab::Auth::Ldap::Config.new(provider)
        end

        def user_filter(login)
          # Allow LDAP users to authenticate by using their GitLab username in case
          # their LDAP username does not match GitLab username or
          # their LDAP username collide with another user's GitLab username.
          # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186848
          uid = if ldap_user_is_allowed_to_authenticate_with_gitlab_username?
                  ::Gitlab::Auth::Ldap::Person.find_by_dn(
                    user.ldap_identity.extern_uid,
                    Gitlab::Auth::Ldap::Adapter.new(provider)
                  )&.uid
                end

          uid ||= login

          filter = Net::LDAP::Filter.equals(config.uid, uid)

          # Apply LDAP user filter if present
          if config.user_filter.present?
            filter = Net::LDAP::Filter.join(filter, config.constructed_user_filter)
          end

          filter
        end

        private

        def ldap_user_is_allowed_to_authenticate_with_gitlab_username?
          user && user.ldap_user? && Feature.enabled?(:allow_ldap_users_to_authenticate_with_gitlab_username, user)
        end
      end
    end
  end
end
