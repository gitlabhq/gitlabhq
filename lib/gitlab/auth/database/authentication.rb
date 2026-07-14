# frozen_string_literal: true

# These calls help to authenticate to OAuth provider by providing username and password
#

module Gitlab
  module Auth
    module Database
      class Authentication < Gitlab::Auth::OAuth::Authentication
        def login(login, password)
          user if user&.valid_password?(password)
        end
      end
    end
  end
end
