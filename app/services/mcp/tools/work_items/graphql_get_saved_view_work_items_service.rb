# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GraphqlGetSavedViewWorkItemsService < GraphqlService
        register_version '0.1.0', {
          description: 'Fetch a saved view and its work items list from a namespace',
          input_schema: {
            type: 'object',
            properties: {
              # Namespace identification (one set required)
              url: {
                type: 'string',
                description: 'GitLab URL for the namespace (project or group).'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required if URL and project_id are not provided.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if URL and group_id are not provided.'
              },

              # Saved view identification (required)
              saved_view_id: {
                type: 'string',
                description:
                  'The global ID of the saved view (format: gid://gitlab/WorkItems::SavedViews::SavedView/<id>).'
              },

              # Pagination parameters
              after: {
                type: 'string',
                description: 'Cursor for forward pagination. Use endCursor from previous response.'
              },
              first: {
                type: 'integer',
                description: 'Number of work items to return (forward pagination, max 100)',
                minimum: 1,
                maximum: 100
              }
            },
            required: [
              'saved_view_id'
            ]
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          # Not used directly since we orchestrate two tools
          raise NotImplementedError
        end

        def perform_0_1_0(arguments)
          # Step 1: Fetch the saved view to get its filters and sort
          saved_view_result = execute_saved_view_tool(arguments)
          return saved_view_result if saved_view_result[:isError]

          saved_view = saved_view_result[:structuredContent]

          # Step 2: Fetch work items using the saved view's filters
          work_items_result, unsupported_filters = execute_work_items_tool(arguments, saved_view)
          return work_items_result if work_items_result[:isError]

          # Combine saved view metadata with work items
          combined = {
            'savedView' => saved_view,
            'workItems' => work_items_result[:structuredContent]
          }

          append_unsupported_filter_warnings(combined, unsupported_filters)

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(combined) }]
          ::Mcp::Tools::Response.success(formatted_content, combined)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_0_1_0(arguments)
        end

        private

        def append_unsupported_filter_warnings(combined, unsupported_filters)
          return if unsupported_filters.blank?

          combined['warnings'] = [{
            'type' => 'unsupported_filters',
            'message' => "The following saved view filters were not applied and results may be broader " \
              "than expected: #{unsupported_filters.join(', ')}",
            'filters' => unsupported_filters
          }]
        end

        def execute_saved_view_tool(arguments)
          tool = Mcp::Tools::WorkItems::GetSavedViewTool.new(
            current_user: current_user,
            params: arguments,
            version: version
          )

          tool.execute
        end

        def execute_work_items_tool(arguments, saved_view)
          tool = Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool.new(
            current_user: current_user,
            params: arguments.merge(
              filters: saved_view['filters'] || {},
              sort: saved_view['sort']
            ),
            version: version
          )

          result = tool.execute
          [result, tool.unsupported_filters]
        end
      end
    end
  end
end
