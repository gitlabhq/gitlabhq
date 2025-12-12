# frozen_string_literal: true

module Jira
  module Requests
    module Issues
      class ListService < Base
        extend ::Gitlab::Utils::Override

        PER_PAGE = 100
        DEFAULT_FIELDS = %w[assignee created creator id issuetype key
          labels priority project reporter resolutiondate
          status statuscategorychangeddate summary updated description].join(',').freeze

        def initialize(jira_integration, params = {})
          super(jira_integration, params)

          @jql = params[:jql].to_s
          @per_page = (params[:per_page] || PER_PAGE).to_i
        end

        protected

        attr_reader :jql, :per_page

        override :build_service_response
        def build_service_response(response)
          return ServiceResponse.success(payload: empty_payload) if response.blank? || response["issues"].blank?

          build_success_response(response)
        end

        def build_success_response(response)
          raise NotImplementedError, "Subclasses must implement build_success_response"
        end

        def map_issues(response)
          response.map { |v| JIRA::Resource::Issue.build(client, v) }
        end

        def empty_payload
          { issues: [], is_last: true }
        end
      end
    end
  end
end
