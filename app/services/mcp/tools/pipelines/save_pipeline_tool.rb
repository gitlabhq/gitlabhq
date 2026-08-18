# frozen_string_literal: true

module Mcp
  module Tools
    module Pipelines
      class SavePipelineTool < Mcp::Tools::Base::GraphqlTool
        include Gitlab::Utils::StrongMemoize
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        PARENT_PARAMS = %i[url project_id].freeze
        ACTIONS = %w[retry cancel].freeze

        OPERATIONS = {
          create: {
            operation_name: 'pipelineCreate',
            graphql_operation: load_graphql('pipelines/create_pipeline.mutation.graphql')
          },
          retry: {
            operation_name: 'pipelineRetry',
            graphql_operation: load_graphql('pipelines/retry_pipeline.mutation.graphql')
          },
          cancel: {
            operation_name: 'pipelineCancel',
            graphql_operation: load_graphql('pipelines/cancel_pipeline.mutation.graphql')
          }
        }.freeze

        register_version VERSIONS[:v0_1_0], {}

        def graphql_operation
          OPERATIONS.fetch(operation)[:graphql_operation]
        end

        def operation_name
          OPERATIONS.fetch(operation)[:operation_name]
        end

        def build_variables
          { input: operation == :create ? create_input : { id: pipeline_gid } }
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        # The pipeline's own ID selects the target: absent means create a new pipeline,
        # present means a lifecycle action on that pipeline.
        def operation
          return create_operation if params[:pipeline_id].blank?

          action = params[:action].to_s

          unless ACTIONS.include?(action)
            raise ArgumentError, 'Provide action: "retry" or "cancel" when pipeline_id is set'
          end

          action.to_sym
        end
        strong_memoize_attr :operation

        def create_operation
          raise ArgumentError, 'Provide ref to create a pipeline, or pipeline_id and action' if params[:ref].blank?

          :create
        end

        def create_input
          {
            projectPath: project_full_path,
            ref: params[:ref],
            variables: ci_variables,
            inputs: ci_inputs
          }.compact
        end

        def project_full_path
          provided = PARENT_PARAMS.select { |key| params[key].present? }

          raise ArgumentError, 'Provide exactly one of: url or project_id' unless provided.one?

          identifier = provided.first == :url ? parse_parent_url(params[:url])[:path] : params[:project_id]

          find_parent_by_id_or_path!(:project, identifier).full_path
        end

        def pipeline_gid
          ::Gitlab::GlobalId.as_global_id(params[:pipeline_id], model_name: 'Ci::Pipeline').to_s
        end

        def ci_variables
          variables = params[:variables]
          return if variables.blank?

          variables.map do |variable|
            variable = variable.with_indifferent_access

            {
              key: variable[:key],
              value: variable[:value],
              variableType: variable[:variable_type]&.upcase
            }.compact
          end
        end

        def ci_inputs
          inputs = params[:inputs]
          return if inputs.blank?

          inputs.map { |name, value| { name: name.to_s, value: value } }
        end

        def process_result(result)
          processed_result = super

          return processed_result if processed_result[:isError]

          pipeline = processed_result[:structuredContent]&.dig('pipeline')

          return ::Mcp::Tools::Base::Response.error('Operation returned no data') if pipeline.blank?

          payload = format_pipeline(pipeline)

          ::Mcp::Tools::Base::Response.success([{ type: 'text', text: Gitlab::Json.dump(payload) }], payload)
        end

        # PipelineType exposes a global ID and a relative path only, so the plain ID and
        # the absolute URL are built here.
        def format_pipeline(pipeline)
          id = GlobalID.parse(pipeline['id'])&.model_id.to_i
          project_web_url = pipeline.dig('project', 'webUrl')

          {
            action: operation.to_s,
            id: id,
            status: pipeline['status']&.downcase,
            ref: pipeline['ref'],
            web_url: project_web_url.presence && "#{project_web_url}/-/pipelines/#{id}"
          }.compact
        end
      end
    end
  end
end
