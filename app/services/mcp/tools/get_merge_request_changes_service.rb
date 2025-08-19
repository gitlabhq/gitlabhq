# frozen_string_literal: true

module Mcp
  module Tools
    class GetMergeRequestChangesService < ApiService
      extend ::Gitlab::Utils::Override

      # See: https://docs.gitlab.com/api/merge_requests/#list-merge-request-diffs
      override :description
      def description
        'Get information about the merge request including its files and changes.'
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
      def perform(oauth_token, arguments = {}, query = {})
        project_id = CGI.escape(arguments[:id].to_s)
        merge_request_iid = arguments[:merge_request_iid]
        query[:page] = arguments[:page] if arguments[:page]
        query[:per_page] = arguments[:per_page] if arguments[:per_page]

        http_get(oauth_token, "/api/v4/projects/#{project_id}/merge_requests/#{merge_request_iid}/diffs", query)
      end

      private

      override :format_response_content
      def format_response_content(response)
        [{ type: 'text', text: response.map { |item| item['diff'] }.join("\n") }] # rubocop:disable Rails/Pluck -- Array
      end
    end
  end
end
