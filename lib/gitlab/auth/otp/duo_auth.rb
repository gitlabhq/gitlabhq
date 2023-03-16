# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      module DuoAuth
        def duo_auth_enabled?(_user)
          ::Gitlab.config.duo_auth.enabled
        end
      end
    end
  end
end
