# frozen_string_literal: true

module Mcp
  module Tools
    class GetIssueService < ApiService
      extend ::Gitlab::Utils::Override

      # See: https://docs.gitlab.com/api/issues/#single-project-issue
      override :description
      def description
        'Get a single project issue.'
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
            iid: {
              type: 'integer',
              description: 'The internal ID of a project\'s issue.'
            }
          },
          required: %w[id iid]
        }
      end

      protected

      override :perform
      def perform(oauth_token, arguments = {})
        project_id = CGI.escape(arguments[:id].to_s)
        issue_iid = arguments[:iid]

        http_get(oauth_token, "/api/v4/projects/#{project_id}/issues/#{issue_iid}")
      end

      private

      override :format_response_content
      def format_response_content(response)
        [{ type: 'text', text: response['web_url'] }]
      end
    end
  end
end
