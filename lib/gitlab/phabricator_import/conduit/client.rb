# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Conduit
      class Client
        def initialize(phabricator_url, api_token)
          @phabricator_url = phabricator_url
          @api_token = api_token
        end

        def get(path, params: {})
          response = Gitlab::HTTP.get(build_url(path), body: build_params(params), headers: headers)
          Response.parse!(response)
        rescue *Gitlab::HTTP::HTTP_ERRORS => e
          # Wrap all errors from the API into an API-error.
          raise ApiError, e
        end

        private

        attr_reader :phabricator_url, :api_token

        def headers
          { "Accept" => 'application/json' }
        end

        def build_url(path)
          URI.join(phabricator_url, '/api/', path).to_s
        end

        def build_params(params)
          params = params.dup
          params.compact!
          params.reverse_merge!("api.token" => api_token)

          CGI.unescape(params.to_query)
        end
      end
    end
  end
end
