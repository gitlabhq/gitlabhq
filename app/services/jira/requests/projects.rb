# frozen_string_literal: true

module Jira
  module Requests
    class Projects < Base
      extend ::Gitlab::Utils::Override

      private

      override :url
      def url
        '/rest/api/2/project'
      end

      override :build_service_response
      def build_service_response(response)
        return ServiceResponse.success(payload: empty_payload) unless response.present?

        ServiceResponse.success(payload: { projects: map_projects(response), is_last: true })
      end

      def map_projects(response)
        response.map { |v| JIRA::Resource::Project.build(client, v) }.select(&method(:match_query?))
      end

      def match_query?(jira_project)
        query = self.query.to_s.downcase

        jira_project&.key&.downcase&.include?(query) || jira_project&.name&.downcase&.include?(query)
      end

      def empty_payload
        { projects: [], is_last: true }
      end
    end
  end
end
