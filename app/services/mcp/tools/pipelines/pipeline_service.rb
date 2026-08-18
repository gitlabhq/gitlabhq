# frozen_string_literal: true

module Mcp
  module Tools
    module Pipelines
      class PipelineService < Base::AggregatedService
        include Gitlab::Utils::Override

        TOOL_MAPPING = {
          update: :update_pipeline,
          delete: :delete_pipeline
        }.freeze

        OPERATION_ACTIONS = {
          update: 'updated',
          delete: 'deleted'
        }.freeze

        register_version '0.1.0', {
          description: <<~DESC.strip,
            Manage CI/CD pipelines in GitLab projects.

            Examples:
            - Use Update to rename a pipeline or update pipeline metadata
            - Use Delete to remove a pipeline record

            To create, retry, or cancel a pipeline, use the save_pipeline tool instead.
            To list pipelines, use the list_pipelines tool instead.
          DESC
          annotations: {
            readOnlyHint: false,
            destructiveHint: true
          },
          input_schema: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'ID or URL-encoded path of the project'
              },
              pipeline_id: {
                type: 'integer',
                description: 'ID of the pipeline to update or delete.'
              },
              name: {
                type: 'string',
                description: 'New name for the pipeline (for update operation)'
              }
            },
            required: %w[id pipeline_id]
          }
        }

        override :tool_name
        def self.tool_name
          'manage_pipeline'
        end

        protected

        override :perform_default
        def perform_default(arguments = {})
          transformed_args = transform_arguments(arguments)
          params[:arguments] = transformed_args.except(:operation)
          tool = select_tool(transformed_args)

          raise Mcp::Tools::Manager::ToolNotFoundError, self.class.tool_name unless tool

          execute_tool_with_enhanced_response(tool, transformed_args[:operation])
        end

        override :transform_arguments
        def transform_arguments(args)
          operation = detect_operation(args)

          transformed = case operation
                        when :update then args.slice(:id, :pipeline_id, :name)
                        when :delete then args.slice(:id, :pipeline_id)
                        else args
                        end

          transformed.merge(operation: operation)
        end

        override :select_tool
        def select_tool(args)
          tool_name = TOOL_MAPPING[args[:operation]]
          tools.find { |t| t.name.to_sym == tool_name }
        end

        private

        def execute_tool_with_enhanced_response(tool, operation)
          response = tool.execute(request:, params:)

          enhance_response_with_operation(
            response,
            operation: operation,
            tool_name: TOOL_MAPPING[operation],
            action_description: "Pipeline #{OPERATION_ACTIONS[operation]} successfully via #{self.class.tool_name}."
          )
        end

        def detect_operation(args)
          return :update if args[:name].present? && args[:pipeline_id].present?
          return :delete if args[:pipeline_id].present?

          raise ArgumentError, "Cannot determine operation. Provide either: " \
            "(name + pipeline_id) for update, " \
            "or (pipeline_id) alone for delete."
        end
      end
    end
  end
end

Mcp::Tools::Pipelines::PipelineService.prepend_mod
