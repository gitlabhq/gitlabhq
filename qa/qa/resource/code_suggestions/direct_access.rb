# frozen_string_literal: true

module QA
  module Resource
    module CodeSuggestions
      class DirectAccess < Base
        # https://docs.gitlab.com/ee/api/code_suggestions.html#fetch-direct-connection-information
        def self.fetch_direct_connection_details(token)
          response = Support::API.post(
            "#{Runtime::Scenario.gitlab_address}/api/v4/code_suggestions/direct_access",
            nil,
            headers: { Authorization: "Bearer #{token}", 'Content-Type': 'application/json' }
          )
          raise "Unexpected status code #{response.code}" unless response.code == Support::API::HTTP_STATUS_CREATED

          direct_connection_details = Support::API.parse_body(response)

          raise "direct_connection[:base_url] should not be nil" if direct_connection_details[:base_url].nil?
          raise "direct_connection[:token] should not be nil" if direct_connection_details[:token].nil?
          raise "direct_connection[:headers] should not be nil" if direct_connection_details[:headers].nil?

          direct_connection_details
        end
      end
    end
  end
end
