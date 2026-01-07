# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Parent class ListService already excluded
module Jira
  module Requests
    module Issues
      class ServerListService < ListService
        def initialize(jira_integration, params = {})
          super
          @page = (params[:page] || 1).to_i
        end

        private

        attr_reader :page

        override :api_version
        def api_version
          2
        end

        override :url
        def url
          "#{base_api_url}/search?jql=#{CGI.escape(jql)}&maxResults=#{per_page}&startAt=#{start_at}" \
            "&fields=#{DEFAULT_FIELDS}"
        end

        override :build_success_response
        def build_success_response(response)
          ServiceResponse.success(payload: {
            issues: map_issues(response["issues"]),
            is_last: last?(response),
            total_count: response["total"].to_i
          })
        end

        def empty_payload
          super.merge(total_count: 0)
        end

        def last?(response)
          response["total"].to_i <= response["startAt"].to_i + response["issues"].size
        end

        def start_at
          (page - 1) * per_page
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
