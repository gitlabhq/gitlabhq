# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Jwt
      class Symmetric
        include Gitlab::Utils::StrongMemoize

        CONTEXT_QSH_STRING = 'context-qsh'

        def initialize(jwt)
          @jwt = jwt
        end

        def iss_claim
          jwt_headers['iss']
        end

        def sub_claim
          jwt_headers['sub']
        end

        def valid?(shared_secret)
          Atlassian::Jwt.decode(@jwt, shared_secret).present?
        rescue JWT::DecodeError
          false
        end

        def verify_qsh_claim(url_with_query, method, url)
          qsh_claim == Atlassian::Jwt.create_query_string_hash(url_with_query, method, url)
        rescue StandardError
          false
        end

        def verify_context_qsh_claim
          qsh_claim == CONTEXT_QSH_STRING
        end

        private

        def qsh_claim
          jwt_headers['qsh']
        end

        def jwt_headers
          strong_memoize(:jwt_headers) do
            Atlassian::Jwt.decode(@jwt, nil, false).first
          rescue JWT::DecodeError
            {}
          end
        end
      end
    end
  end
end
