# frozen_string_literal: true

module Mcp
  module Tools
    module Pipelines
      class SavePipelineService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Run, retry, or cancel a CI/CD pipeline in a GitLab project. ' \
            'Omit pipeline_id and pass ref to run a new pipeline, and identify the project with ' \
            'exactly one of url or project_id. Pass pipeline_id with action to retry or cancel an ' \
            'existing pipeline.',
          annotations: {
            readOnlyHint: false,
            destructiveHint: true
          },
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the project. Used only when creating a pipeline.'
              },
              project_id: {
                type: 'string',
                description: 'ID or full path of the project. Used only when creating a pipeline.'
              },
              pipeline_id: {
                type: 'integer',
                description: 'ID of an existing pipeline to target. When set, requires action. ' \
                  'Omit to create a new pipeline.'
              },
              action: {
                type: 'string',
                enum: Mcp::Tools::Pipelines::SavePipelineTool::ACTIONS,
                description: 'Lifecycle action to perform on pipeline_id. Required when pipeline_id is set.'
              },
              ref: {
                type: 'string',
                description: 'Branch or tag name. Required to create a pipeline (when pipeline_id is absent).'
              },
              variables: {
                type: 'array',
                description: 'Pipeline variables to create the pipeline with.',
                items: {
                  type: 'object',
                  properties: {
                    key: { type: 'string', description: 'Name of the variable.' },
                    value: { type: 'string', description: 'Value of the variable.' },
                    variable_type: {
                      type: 'string',
                      enum: %w[env_var file],
                      description: 'Type of the variable. Defaults to env_var.'
                    }
                  },
                  required: %w[key value]
                }
              },
              inputs: {
                type: 'object',
                description: 'Pipeline input parameters as key-value pairs.'
              }
            }
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Pipelines::SavePipelineTool
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
