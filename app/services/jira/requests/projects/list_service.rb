# frozen_string_literal: true

module Jira
  module Requests
    module Projects
      class ListService < Base
        extend ::Gitlab::Utils::Override

        def initialize(jira_integration, params = {})
          super(jira_integration, params)

          @query = params[:query]
        end

        private

        attr_reader :query

        override :url
        def url
          "#{base_api_url}/project"
        end

        override :build_service_response
        def build_service_response(response)
          return ServiceResponse.success(payload: empty_payload) unless response.present?

          ServiceResponse.success(payload: { projects: map_projects(response), is_last: true })
        end

        def map_projects(response)
          response
            .map { |v| JIRA::Resource::Project.build(client, v) }
            .select { |jira_project| match_query?(jira_project) }
        end

        def match_query?(jira_project)
          downcase_query = query.to_s.downcase

          jira_project&.key&.downcase&.include?(downcase_query) || jira_project&.name&.downcase&.include?(downcase_query)
        end

        def empty_payload
          { projects: [], is_last: true }
        end
      end
    end
  end
end
