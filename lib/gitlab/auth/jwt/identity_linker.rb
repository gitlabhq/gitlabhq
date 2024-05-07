# frozen_string_literal: true

module Gitlab
  module Auth
    module Jwt
      class IdentityLinker < ::Gitlab::Auth::OAuth::IdentityLinker
        extend ::Gitlab::Utils::Override

        # For security purposes, all requests to link a JWT identity with an existing
        # user that is currently authenticated require user authorization.
        override :authorization_required?
        def authorization_required?
          true if unlinked?
        end
      end
    end
  end
end
