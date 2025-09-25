# frozen_string_literal: true

module Mcp
  module Tools
    class CreateIssueService < ApiService
      extend ::Gitlab::Utils::Override

      # See: https://docs.gitlab.com/api/issues/#new-issue
      override :description
      def description
        'Create a new project issue.'
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
            title: {
              type: 'string',
              description: 'The title of an issue.',
              minLength: 1
            },
            description: {
              type: 'string',
              description: 'The description of an issue. Limited to 1,048,576 characters.'
            },
            assignee_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'The IDs of the users to assign the issue to. Premium and Ultimate only.'
            },
            milestone_id: {
              type: 'integer',
              description: 'The global ID of a milestone to assign issue. To find the milestone_id associated \
              with a milestone, view an issue with the milestone assigned \
              and use the API to retrieve the issue\'s details.'
            },
            epic_id: {
              type: 'integer',
              description: 'ID of the epic to add the issue to. Valid values are greater than or equal to 0. \
              Premium and Ultimate only.',
              minimum: 0
            },
            labels: {
              type: 'string',
              description: 'Comma-separated label names to assign to the new issue. If a label does not already exist, \
               this creates a new project label and assigns it to the issue.'
            },
            confidential: {
              type: 'boolean',
              description: 'Set an issue to be confidential. Default is false.',
              default: false
            }
          },
          required: %w[id title],
          additionalProperties: false
        }
      end

      protected

      override :perform
      def perform(arguments = {}, _query = {})
        project_id = CGI.escape(arguments[:id].to_s)
        path = "/api/v4/projects/#{project_id}/issues"
        body = arguments.except(:id)

        http_post(access_token, path, body)
      end

      private

      override :format_response_content
      def format_response_content(response)
        [{ type: 'text', text: response['web_url'] }]
      end
    end
  end
end
