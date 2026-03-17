# frozen_string_literal: true

module Mcp
  module Tools
    class PipelineService < AggregatedService
      include Gitlab::Utils::Override

      TOOL_MAPPING = {
        list: :list_pipelines,
        create: :create_pipeline,
        update: :update_pipeline,
        retry: :retry_pipeline,
        cancel: :cancel_pipeline,
        delete: :delete_pipeline
      }.freeze

      OPERATION_ACTIONS = {
        list: 'listed',
        create: 'created',
        update: 'updated',
        retry: 'retried',
        cancel: 'canceled',
        delete: 'deleted'
      }.freeze

      register_version '0.1.0', {
        description: <<~DESC.strip,
          Manage CI/CD pipelines in GitLab projects.

          Examples:
          - Use List to show pipelines, get pipeline status, or see what pipelines exist
          - Use Create to run a pipeline, trigger a build, or start CI on a branch
          - Use Update to rename a pipeline or update pipeline metadata
          - Use Retry to run a pipeline again, rerun, or retry a failed build
          - Use Cancel to stop a pipeline, abort a build, or kill a running job
          - Use Delete to remove a pipeline record
        DESC
        input_schema: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'ID or URL-encoded path of the project'
            },
            list: {
              type: 'boolean',
              description: 'Set to true to list all pipelines. Required when user says "list pipelines".'
            },
            ref: {
              type: 'string',
              description: 'Branch or tag name (for create operation or filtering list)'
            },
            pipeline_id: {
              type: 'integer',
              description: 'ID of the pipeline. Must be combined with retry:true or cancel:true.'
            },
            retry: {
              type: 'boolean',
              description: 'Set to true to retry a pipeline. Required when user says "retry pipeline X".'
            },
            cancel: {
              type: 'boolean',
              description: 'Set to true to cancel a pipeline. Required when user says "cancel pipeline X".'
            },
            name: {
              type: 'string',
              description: 'New name for the pipeline (for update operation)'
            },
            variables: {
              description: 'Pipeline variables as array format for create operation'
            },
            inputs: {
              type: 'object',
              description: 'Pipeline input parameters as key-value pairs'
            },
            page: {
              type: 'integer',
              description: 'Page number for pagination (default: 1)'
            },
            per_page: {
              type: 'integer',
              description: 'Number of items per page (default: 20, max: 100)'
            }
          },
          required: ['id'],
          additionalProperties: false
        }
      }

      override :tool_name
      def self.tool_name
        'manage_pipeline'
      end

      override :annotations
      def annotations
        {
          readOnlyHint: false,
          destructiveHint: true
        }
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
        base_args = args.except(:list, :retry, :cancel)

        transformed = case operation
                      when :create then base_args.slice(:id, :ref, :variables, :inputs)
                      when :list then base_args.slice(:id, :ref, :page, :per_page)
                      when :update then base_args.slice(:id, :pipeline_id, :name)
                      when :retry, :cancel, :delete then base_args.slice(:id, :pipeline_id)
                      else base_args
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
        return :list if args[:list] == true
        return :retry if args[:retry] == true && args[:pipeline_id].present?
        return :cancel if args[:cancel] == true && args[:pipeline_id].present?
        return :update if args[:name].present? && args[:pipeline_id].present?
        return :create if args[:ref].present?
        return :delete if args[:pipeline_id].present?

        raise ArgumentError, "Cannot determine operation. Provide either: " \
          "(list: true) to list pipelines, (ref) for create, " \
          "(name + pipeline_id) for update, " \
          "(retry: true + pipeline_id) for retry, (cancel: true + pipeline_id) for cancel, " \
          "or (pipeline_id) alone for delete"
      end
    end
  end
end

Mcp::Tools::PipelineService.prepend_mod
