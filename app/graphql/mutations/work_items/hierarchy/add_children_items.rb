# frozen_string_literal: true

module Mutations
  module WorkItems
    module Hierarchy
      class AddChildrenItems < BaseMutation
        graphql_name 'WorkItemHierarchyAddChildrenItems'
        description "Adds children to a given work item's hierarchy by Global ID."

        include Mutations::WorkItems::Widgetable

        authorize :read_work_item

        argument :children_ids, [::Types::GlobalIDType[::WorkItem]],
          required: true,
          description: 'Global IDs of children work items.',
          loads: ::Types::WorkItemType,
          as: :children
        argument :id,
          ::Types::GlobalIDType[::WorkItem],
          required: true,
          description: 'Global ID of the work item.'

        field :added_children, [::Types::WorkItemType],
          null: false,
          description: 'Work items that were added as children.'

        def resolve(id:, **attributes)
          Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/408575')

          work_item = authorized_find!(id: id)
          children = attributes[:children]

          widget_attributes = { hierarchy_widget: { children: children } }
          widget_params = extract_widget_params!(work_item.work_item_type, widget_attributes, work_item.resource_parent)

          update_result = ::WorkItems::UpdateService.new(
            container: work_item.resource_parent,
            current_user: current_user,
            params: {},
            widget_params: widget_params
          ).execute(work_item)

          # Find newly added children using the provided children_ids
          if update_result[:status] == :success
            updated_work_item = update_result[:work_item]
            children_ids = children.map(&:id)
            added_children = updated_work_item.work_item_children.select { |child| children_ids.include?(child.id) }
          else
            added_children = []
          end

          {
            added_children: added_children,
            errors: Array.wrap(update_result[:message])
          }
        end
      end
    end
  end
end
