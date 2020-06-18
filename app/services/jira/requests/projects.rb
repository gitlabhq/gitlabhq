# frozen_string_literal: true

module Jira
  module Requests
    class Projects < Base
      extend ::Gitlab::Utils::Override

      private

      override :url
      def url
        '/rest/api/2/project/search?query=%{query}&maxResults=%{limit}&startAt=%{start_at}' %
        { query: CGI.escape(query.to_s), limit: limit.to_i, start_at: start_at.to_i }
      end

      override :build_service_response
      def build_service_response(response)
        return ServiceResponse.success(payload: empty_payload) unless response['values'].present?

        ServiceResponse.success(payload: { projects: map_projects(response), is_last: response['isLast'] })
      end

      def map_projects(response)
        response['values'].map { |v| JIRA::Resource::Project.build(client, v) }
      end

      def empty_payload
        { projects: [], is_last: true }
      end
    end
  end
end
