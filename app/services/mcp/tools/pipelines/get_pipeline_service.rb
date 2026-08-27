# frozen_string_literal: true

module Mcp
  module Tools
    module Pipelines
      class GetPipelineService < Base::GraphqlService
        register_version '0.1.0', {
          description: <<~DESC.strip,
            Get a CI/CD pipeline in a GitLab project, and optionally its jobs, downstream pipelines, or
            bridge (trigger) jobs. A bridge job's downstream pipeline is omitted if you do not have
            access to it. To list pipelines, use the list_pipelines tool instead.
          DESC
          annotations: {
            readOnlyHint: true
          },
          input_schema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'ID or full path of the project'
              },
              pipeline_id: {
                type: 'integer',
                description: 'ID of the pipeline'
              },
              include: {
                type: 'array',
                description: 'Facet to include alongside the pipeline, one per call: jobs, downstream_pipelines, ' \
                  'or bridge_jobs.',
                items: {
                  type: 'string',
                  enum: GetPipelineTool::FACETS.values
                },
                maxItems: 1
              },
              job_status: {
                type: 'string',
                enum: ::Ci::HasStatus::AVAILABLE_STATUSES,
                description: 'Filters the jobs facet by status (for example, failed). ' \
                  'Only applies when include is jobs.'
              },
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(
                items: 'items for the selected include facet',
                cursor_style: :snake_case
              )
            },
            required: %w[id pipeline_id]
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Pipelines::GetPipelineTool
        end

        def perform_v0_1_0(arguments)
          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end
      end
    end
  end
end
