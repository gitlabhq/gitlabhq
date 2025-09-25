# frozen_string_literal: true

module Mcp
  module Tools
    class GetMergeRequestService < ApiService
      extend ::Gitlab::Utils::Override

      # See: https://docs.gitlab.com/api/merge_requests/#get-single-mr
      override :description
      def description
        'Get a single merge request.'
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
            }
          },
          required: %w[id merge_request_iid],
          additionalProperties: false
        }
      end

      protected

      override :perform
      def perform(arguments = {}, _query = {})
        project_id = CGI.escape(arguments[:id].to_s)
        merge_request_iid = arguments[:merge_request_iid]

        http_get(access_token, "/api/v4/projects/#{project_id}/merge_requests/#{merge_request_iid}")
      end

      private

      override :format_response_content
      def format_response_content(response)
        [{ type: 'text', text: response['web_url'] }]
      end
    end
  end
end
