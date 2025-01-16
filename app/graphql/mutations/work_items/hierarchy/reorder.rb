# frozen_string_literal: true

module Mutations
  module WorkItems
    module Hierarchy
      class Reorder < BaseMutation
        graphql_name 'workItemsHierarchyReorder'
        description 'Reorder a work item in the hierarchy tree.'

        argument :id, ::Types::GlobalIDType[::WorkItem],
          required: true, description: 'Global ID of the work item to be reordered.'

        argument :adjacent_work_item_id,
          ::Types::GlobalIDType[::WorkItem],
          required: false,
          description: 'ID of the work item to move next to. For example, the item above or below.'

        argument :parent_id, ::Types::GlobalIDType[::WorkItem],
          required: false,
          description: 'Global ID of the new parent work item.'

        argument :relative_position,
          ::Types::RelativePositionTypeEnum,
          required: false,
          description: 'Position relative to the adjacent work item. Valid values are `BEFORE` or `AFTER`.'

        field :work_item, ::Types::WorkItemType,
          null: true, description: 'Work item after mutation.'

        field :adjacent_work_item, ::Types::WorkItemType,
          null: true, description: 'Adjacent work item after mutation.'

        field :parent_work_item, ::Types::WorkItemType,
          null: true, description: "Work item's parent after mutation."

        authorize :read_work_item

        def ready?(**args)
          validate_position_args!(args)

          @work_item = authorized_find!(id: args.delete(:id))
          @adjacent_item = authorized_find!(id: args.delete(:adjacent_work_item_id)) if args[:adjacent_work_item_id]
          new_parent = authorized_find!(id: args.delete(:parent_id)) if args[:parent_id]
          @parent = new_parent || work_item.work_item_parent

          validate_parent!

          super
        end

        def resolve(**args)
          arguments = {
            target_issuable: work_item,
            adjacent_work_item: adjacent_item,
            relative_position: args.delete(:relative_position)
          }

          service_response = ::WorkItems::ParentLinks::ReorderService.new(parent, current_user, arguments).execute

          {
            work_item: work_item,
            adjacent_work_item: adjacent_item,
            parent_work_item: parent,
            errors: service_response[:status] == :error ? Array.wrap(service_response[:message]) : []
          }
        end

        private

        attr_reader :work_item, :parent, :adjacent_item

        def validate_parent!
          return unless adjacent_item
          return if parent == adjacent_item.work_item_parent

          raise Gitlab::Graphql::Errors::ArgumentError,
            _("The adjacent work item's parent must match the moving work item's parent.")
        end

        def validate_position_args!(args)
          return unless args.slice(:adjacent_work_item_id, :relative_position).one?

          raise Gitlab::Graphql::Errors::ArgumentError,
            _('Both adjacentWorkItemId and relativePosition are required.')
        end

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::WorkItem).sync
        end
      end
    end
  end
end
