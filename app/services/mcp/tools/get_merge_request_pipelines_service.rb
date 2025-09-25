# frozen_string_literal: true

module Mcp
  module Tools
    class GetMergeRequestPipelinesService < ApiService
      extend ::Gitlab::Utils::Override

      # See: https://docs.gitlab.com/api/merge_requests/#list-merge-request-pipelines
      override :description
      def description
        'Get pipelines for a merge request.'
      end

      override :input_schema
      def input_schema
        {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'The global ID or URL-encoded path of the project.',
              minLength: 1
            },
            merge_request_iid: {
              type: 'integer',
              description: 'The internal ID of the project merge request.'
            },
            **input_schema_pagination_params
          },
          required: %w[id merge_request_iid],
          additionalProperties: false
        }
      end

      protected

      override :perform
      def perform(arguments = {}, query = {})
        project_id = CGI.escape(arguments[:id].to_s)
        merge_request_iid = arguments[:merge_request_iid]
        query[:page] = arguments[:page] if arguments[:page]
        query[:per_page] = arguments[:per_page] if arguments[:per_page]

        http_get(access_token, "/api/v4/projects/#{project_id}/merge_requests/#{merge_request_iid}/pipelines", query)
      end

      private

      override :format_response_content
      def format_response_content(response)
        formatted_pipelines = response.map do |pipeline|
          "Pipeline ##{pipeline['id']} - #{pipeline['status']} (#{pipeline['ref']})\nSHA: #{pipeline['sha']}"
        end
        [{ type: 'text', text: formatted_pipelines.join("\n\n") }]
      end
    end
  end
end
