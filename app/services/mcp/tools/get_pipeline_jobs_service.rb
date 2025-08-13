# frozen_string_literal: true

module Mcp
  module Tools
    class GetPipelineJobsService < ApiService
      extend ::Gitlab::Utils::Override

      # See: https://docs.gitlab.com/api/jobs/#list-pipeline-jobs
      override :description
      def description
        'Get all jobs associated with a pipeline.'
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
            pipeline_id: {
              type: 'integer',
              description: 'The ID of the pipeline.'
            },
            **input_schema_pagination_params
          },
          required: %w[id pipeline_id],
          additionalProperties: false
        }
      end

      protected

      override :perform
      def perform(oauth_token, arguments = {}, query = {})
        project_id = CGI.escape(arguments[:id].to_s)
        pipeline_id = arguments[:pipeline_id]
        query[:page] = arguments[:page] if arguments[:page]
        query[:per_page] = arguments[:per_page] if arguments[:per_page]

        http_get(oauth_token, "/api/v4/projects/#{project_id}/pipelines/#{pipeline_id}/jobs", query)
      end

      private

      override :format_response_content
      def format_response_content(response)
        [{ type: 'text', text: response.map { |item| item['web_url'] }.join("\n") }] # rubocop:disable Rails/Pluck -- Array
      end
    end
  end
end
