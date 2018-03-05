# These calls help to authenticate to OAuth provider by providing username and password
#

module Gitlab
  module Auth
    module OAuth
      class Authentication
        attr_reader :provider, :user

        def initialize(provider, user = nil)
          @provider = provider
          @user = user
        end

        def login(login, password)
          raise NotImplementedError
        end
      end
    end
  end
end
