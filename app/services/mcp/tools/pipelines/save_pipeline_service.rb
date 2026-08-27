# frozen_string_literal: true

module Mcp
  module Tools
    module Pipelines
      class SavePipelineService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Run, retry, cancel, or rename a CI/CD pipeline in a GitLab project. ' \
            'Omit pipeline_id and pass ref to run a new pipeline, and identify the project with ' \
            'exactly one of url or project_id. Pass pipeline_id with action to retry, cancel, or ' \
            'update an existing pipeline; update renames it and requires name.',
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
              name: {
                type: 'string',
                description: 'New pipeline name. Required for action: "update".'
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
          # update has no GraphQL mutation, so it dispatches to the metadata
          # service here and must never reach SavePipelineTool's OPERATIONS.
          return perform_update(arguments) if arguments[:action].to_s == 'update'

          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end

        private

        def perform_update(arguments)
          raise ArgumentError, 'Provide pipeline_id to rename a pipeline' if arguments[:pipeline_id].blank?
          raise ArgumentError, 'Provide name to rename the pipeline' if arguments[:name].blank?

          pipeline = ::Ci::Pipeline.find_by_id(arguments[:pipeline_id])

          unless pipeline && Ability.allowed?(current_user, :read_pipeline, pipeline)
            return ::Mcp::Tools::Base::Response.error('Pipeline not found or inaccessible.')
          end

          response = ::Ci::Pipelines::UpdateMetadataService
            .new(pipeline, current_user: current_user, params: { name: arguments[:name] })
            .execute

          return update_response(response.payload) if response.success?

          # Readable but not renamable maps to the same uniform message; other
          # failures carry the service's own error strings.
          if response.reason == :forbidden
            return ::Mcp::Tools::Base::Response.error('Pipeline not found or inaccessible.')
          end

          ::Mcp::Tools::Base::Response.error(Array(response.payload).join(', ').presence || response.message)
        end

        def update_response(pipeline)
          structured_content = {
            action: 'update',
            id: pipeline.id,
            name: pipeline.name,
            status: pipeline.status,
            ref: pipeline.ref,
            web_url: "#{pipeline.project.web_url}/-/pipelines/#{pipeline.id}"
          }.compact

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(structured_content) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, structured_content)
        end
      end
    end
  end
end
