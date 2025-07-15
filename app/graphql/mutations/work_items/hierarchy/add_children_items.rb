# frozen_string_literal: true

module Mutations
  module WorkItems
    module Hierarchy
      class AddChildrenItems < BaseMutation
        graphql_name 'WorkItemHierarchyAddChildrenItems'
        description "Adds children to a given work item's hierarchy by Global ID."

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

          update_result = ::WorkItems::ParentLinks::CreateService
            .new(work_item, current_user, { issuable_references: children })
            .execute

          {
            added_children: update_result[:created_references]&.map(&:work_item) || [],
            errors: Array.wrap(update_result[:message])
          }
        end
      end
    end
  end
end
