# frozen_string_literal: true

module Gitlab
  module Auth
    module Atlassian
      class IdentityLinker < OmniauthIdentityLinkerBase
        extend ::Gitlab::Utils::Override
        include ::Gitlab::Utils::StrongMemoize

        private

        override :identity
        def identity
          strong_memoize(:identity) do
            current_user.atlassian_identity || build_atlassian_identity
          end
        end

        def build_atlassian_identity
          identity = current_user.build_atlassian_identity
          ::Gitlab::Auth::Atlassian::User.assign_identity_from_auth_hash!(identity, auth_hash)
        end

        def auth_hash
          ::Gitlab::Auth::Atlassian::AuthHash.new(oauth)
        end
      end
    end
  end
end
