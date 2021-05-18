# frozen_string_literal: true

# These calls help to authenticate to OAuth provider by providing username and password
#

module Gitlab
  module Auth
    module Database
      class Authentication < Gitlab::Auth::OAuth::Authentication
        def login(login, password)
          return false unless Gitlab::CurrentSettings.password_authentication_enabled_for_git?
          return false if user.password_based_login_forbidden?

          return user if user&.valid_password?(password)
        end
      end
    end
  end
end
