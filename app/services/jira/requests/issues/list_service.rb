# frozen_string_literal: true

module Jira
  module Requests
    module Issues
      class ListService < Base
        extend ::Gitlab::Utils::Override

        PER_PAGE = 100

        def initialize(jira_service, params = {})
          super(jira_service, params)

          @jql = params[:jql].to_s
          @page = params[:page].to_i || 1
        end

        private

        attr_reader :jql, :page

        override :url
        def url
          "#{base_api_url}/search?jql=#{CGI.escape(jql)}&startAt=#{start_at}&maxResults=#{PER_PAGE}&fields=*all"
        end

        override :build_service_response
        def build_service_response(response)
          return ServiceResponse.success(payload: empty_payload) if response.blank? || response["issues"].blank?

          ServiceResponse.success(payload: {
            issues: map_issues(response["issues"]),
            is_last: last?(response),
            total_count: response["total"].to_i
          })
        end

        def map_issues(response)
          response.map { |v| JIRA::Resource::Issue.build(client, v) }
        end

        def empty_payload
          { issues: [], is_last: true, total_count: 0 }
        end

        def last?(response)
          response["total"].to_i <= response["startAt"].to_i + response["issues"].size
        end

        def start_at
          (page - 1) * PER_PAGE
        end
      end
    end
  end
end
