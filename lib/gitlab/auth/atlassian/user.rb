# frozen_string_literal: true

module Gitlab
  module Auth
    module Atlassian
      class User < Gitlab::Auth::OAuth::User
        def self.assign_identity_from_auth_hash!(identity, auth_hash)
          identity.extern_uid = auth_hash.uid
          identity.token = auth_hash.token
          identity.refresh_token = auth_hash.refresh_token
          identity.expires_at = Time.at(auth_hash.expires_at).utc.to_datetime if auth_hash.expires?

          identity
        end

        protected

        def find_by_uid_and_provider
          ::Atlassian::Identity.find_by_extern_uid(auth_hash.uid)&.user
        end

        def add_or_update_user_identities
          return unless gl_user

          identity = gl_user.atlassian_identity || gl_user.build_atlassian_identity
          self.class.assign_identity_from_auth_hash!(identity, auth_hash)
        end

        def auth_hash=(auth_hash)
          @auth_hash = ::Gitlab::Auth::Atlassian::AuthHash.new(auth_hash)
        end
      end
    end
  end
end
