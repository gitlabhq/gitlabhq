# frozen_string_literal: true

module Gitlab
  module Auth
    module Atlassian
      class AuthHash < Gitlab::Auth::OAuth::AuthHash
        def token
          credentials[:token]
        end

        def refresh_token
          credentials[:refresh_token]
        end

        def expires?
          credentials[:expires]
        end

        def expires_at
          credentials[:expires_at]
        end

        private

        def credentials
          auth_hash[:credentials]
        end
      end
    end
  end
end
