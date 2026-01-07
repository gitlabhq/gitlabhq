# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Parent class ListService already excluded
module Jira
  module Requests
    module Issues
      class CloudListService < ListService
        def initialize(jira_integration, params = {})
          super
          @next_page_token = params[:next_page_token]
        end

        private

        attr_reader :next_page_token

        override :api_version
        def api_version
          3
        end

        override :url
        def url
          base_url = "#{base_api_url}/search/jql?jql=#{CGI.escape(jql)}&maxResults=#{per_page}&fields=#{DEFAULT_FIELDS}"

          if next_page_token.present?
            "#{base_url}&nextPageToken=#{CGI.escape(next_page_token)}"
          else
            base_url
          end
        end

        override :build_success_response
        def build_success_response(response)
          ServiceResponse.success(payload: {
            issues: map_issues(response["issues"]),
            is_last: response["isLast"] || false,
            next_page_token: response["nextPageToken"]
          })
        end

        def empty_payload
          super.merge(next_page_token: nil)
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
