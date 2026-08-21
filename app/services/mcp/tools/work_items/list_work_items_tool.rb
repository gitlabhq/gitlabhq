# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class ListWorkItemsTool < BaseTool
        register_version VERSIONS[:v0_1_0], {
          operation_name: 'namespace',
          # Lambda defers evaluation until after prepend_mod applies the EE
          # module to WorkItemsQueryBuilder, so EE filters are included in
          # the composed GraphQL query.
          graphql_operation: -> { WorkItemsQueryBuilder.build_query(projection: :compact) }
        }

        def build_variables
          ensure_single_parent_identifier!

          parent_info = resolve_parent

          variables, _unsupported = WorkItemsQueryBuilder.build_variables(
            full_path: parent_info[:full_path],
            filters: agent_filters,
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

        # Overridden in EE, where licensed filters are available.
        def agent_filters
          {
            'state' => params[:state],
            'search' => params[:search],
            'authorUsername' => params[:author_username],
            'assigneeUsernames' => params[:assignee_usernames],
            'labelName' => params[:label_name],
            'milestoneTitle' => params[:milestone_title],
            'milestoneWildcardId' => params[:milestone_wildcard_id],
            'types' => params[:types],
            'createdAfter' => params[:created_after],
            'createdBefore' => params[:created_before],
            'updatedAfter' => params[:updated_after],
            'updatedBefore' => params[:updated_before],
            'dueAfter' => params[:due_after],
            'dueBefore' => params[:due_before]
          }.compact
        end

        private

        def ensure_single_parent_identifier!
          given = [:url, :project_id, :group_id].select { |key| params[key].present? }
          return if given.length <= 1

          raise ArgumentError, "Provide exactly one of url, project_id, or group_id (got #{given.join(', ')})"
        end

        def process_result(result)
          return resource_not_found_error if resource_not_found?(result)

          processed = super
          return processed if processed[:isError]

          connection = processed[:structuredContent]&.dig('workItems')
          return ::Mcp::Tools::Base::Response.error('Operation returned no data') unless connection

          structured_content = {
            'work_items' => connection['nodes'],
            'pageInfo' => connection['pageInfo']&.slice('endCursor', 'hasNextPage')
          }

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(structured_content) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, structured_content)
        end

        def resource_not_found_error
          ::Mcp::Tools::Base::Response.error(
            'Project or group not found: it does not exist or you do not have access to it.'
          )
        end
      end
    end
  end
end

Mcp::Tools::WorkItems::ListWorkItemsTool.prepend_mod
