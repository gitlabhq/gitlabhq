# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class CreateWorkItemTool < BaseTool
        include SaveWorkItemCommon

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'workItemCreate',
          graphql_operation: load_graphql('work_items/create_work_item.mutation.graphql')
        }

        UPDATE_ONLY_PARAMS = %i[state add_label_ids add_labels remove_label_ids remove_labels
          todo_action todo_id clear_weight].freeze

        def build_variables
          ensure_single_parent_identifier!
          validate_create_params!

          parent = resolve_parent

          input = {
            namespacePath: parent[:full_path],
            workItemTypeId: resolve_work_item_type_id(parent[:record]),
            title: params[:title],
            confidential: params[:confidential],
            descriptionWidget: description_widget,
            assigneesWidget: assignees_widget,
            labelsWidget: labels_widget,
            milestoneWidget: milestone_widget,
            startAndDueDateWidget: start_and_due_date_widget,
            hierarchyWidget: hierarchy_widget,
            healthStatusWidget: health_status_widget,
            weightWidget: weight_widget,
            statusWidget: status_widget,
            agentPlanWidget: agent_plan_widget
          }.compact

          { input: input }
        end

        private

        def validate_create_params!
          raise ArgumentError, 'title is required when creating a work item' if params[:title].blank?
          raise ArgumentError, 'type_name is required when creating a work item' if params[:type_name].blank?

          UPDATE_ONLY_PARAMS.each do |param|
            next unless params.key?(param)

            raise ArgumentError, "#{param} can only be used when updating (provide work_item_iid)"
          end
        end

        def resolve_work_item_type_id(parent_record)
          provider = ::WorkItems::TypesFramework::Provider.new(parent_record)
          available_types = provider.available_types
          type = available_types.find { |available| available.name.casecmp?(params[:type_name]) }

          unless type
            raise ArgumentError, "Work item type '#{params[:type_name]}' not found. " \
              "Valid types: #{available_types.map(&:name).join(', ')}"
          end

          type.to_global_id.to_s
        end

        def labels_widget
          label_gids = combined_label_gids(:label_ids, :labels)

          { labelIds: label_gids } if label_gids
        end

        def weight_widget
          return unless params.key?(:weight)

          { weight: params[:weight] }
        end
      end
    end
  end
end
