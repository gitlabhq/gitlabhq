# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class UpdateWorkItemTool < BaseTool
        include SaveWorkItemCommon

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'workItemUpdate',
          graphql_operation: load_graphql('work_items/update_work_item.mutation.graphql')
        }

        CREATE_ONLY_PARAMS = %i[type_name label_ids labels].freeze

        def build_variables
          ensure_single_parent_identifier!
          validate_update_params!

          input = {
            id: resolve_work_item_id,
            title: params[:title],
            confidential: params[:confidential],
            stateEvent: state_event,
            descriptionWidget: description_widget,
            assigneesWidget: assignees_widget,
            labelsWidget: labels_widget,
            milestoneWidget: milestone_widget,
            startAndDueDateWidget: start_and_due_date_widget,
            hierarchyWidget: hierarchy_widget,
            currentUserTodosWidget: current_user_todos_widget,
            healthStatusWidget: health_status_widget,
            weightWidget: weight_widget,
            statusWidget: status_widget,
            agentPlanWidget: agent_plan_widget
          }.compact

          { input: input }
        end

        private

        def validate_update_params!
          CREATE_ONLY_PARAMS.each do |param|
            next unless params.key?(param)

            raise ArgumentError, "#{param} can only be used when creating (omit work_item_iid)"
          end

          return unless params.key?(:todo_id) && !params.key?(:todo_action)

          raise ArgumentError, 'todo_action is required when todo_id is provided'
        end

        def state_event
          return unless params.key?(:state)

          params[:state] == 'closed' ? 'CLOSE' : 'REOPEN'
        end

        def labels_widget
          {
            addLabelIds: combined_label_gids(:add_label_ids, :add_labels),
            removeLabelIds: combined_label_gids(:remove_label_ids, :remove_labels)
          }.compact.presence
        end

        # Clearing a weight requires an explicit null in the mutation input; the widget
        # hash itself is non-nil, so the surrounding compact keeps the inner nil intact.
        def weight_widget
          return { weight: nil } if params[:clear_weight]
          return unless params.key?(:weight)

          { weight: params[:weight] }
        end

        def current_user_todos_widget
          return unless params.key?(:todo_action)

          {
            action: params[:todo_action].to_s.upcase,
            todoId: params[:todo_id] && normalize_gid(params[:todo_id], 'Todo')
          }.compact
        end

        def process_result(result)
          if access_denied?(result)
            return ::Mcp::Tools::Base::Response.error(
              'Work item not found: it does not exist or you do not have access to it.'
            )
          end

          super
        end

        # Mutation authorization failures (readable but not updatable) surface as a top-level
        # GraphQL error; missing/unreadable items already raise upstream in build_variables.
        def access_denied?(result)
          Array(result['errors']).any? do |error|
            error.is_a?(Hash) &&
              error['message'] == ::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
          end
        end
      end
    end
  end
end
