# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetSavedViewWorkItemsTool < BaseTool
        class << self
          # Kept as delegators: the register_version lambda and existing specs
          # reference these on the tool class; the definitions live in the
          # shared WorkItemsQueryBuilder.
          def filter_definitions
            WorkItemsQueryBuilder.filter_definitions
          end

          def widget_fragments
            WorkItemsQueryBuilder.widget_fragments
          end

          def build_query
            WorkItemsQueryBuilder.build_query
          end
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'namespace',
          # Lambda defers build_query evaluation until after prepend_mod
          # applies the EE module to WorkItemsQueryBuilder, so EE
          # filter_definitions and widget_fragments are included.
          graphql_operation: -> { build_query }
        }

        attr_reader :unsupported_filters

        def initialize(current_user:, params:, version: nil)
          super
          @unsupported_filters = []
        end

        def build_variables
          parent_info = resolve_parent
          filters = (params[:filters] || {}).stringify_keys

          variables, @unsupported_filters = WorkItemsQueryBuilder.build_variables(
            full_path: parent_info[:full_path],
            filters: filters,
            sort: params[:sort],
            first: params[:first],
            after: params[:after]
          )

          variables
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def process_result(result)
          processed = super
          return processed if processed[:isError]

          work_items_data = processed[:structuredContent]['workItems']
          return ::Mcp::Tools::Base::Response.error("The work items are inaccessible") unless work_items_data

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(work_items_data) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, work_items_data)
        end
      end
    end
  end
end
