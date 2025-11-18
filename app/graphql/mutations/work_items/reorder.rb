# frozen_string_literal: true

module Mutations
  module WorkItems
    class Reorder < BaseMutation
      graphql_name 'workItemsReorder'
      description 'Reorders a work item.'

      argument :id,
        ::Types::GlobalIDType[::WorkItem],
        required: true,
        description: 'Global ID of the work item to be reordered.'

      argument :move_before_id,
        ::Types::GlobalIDType[::WorkItem],
        required: false,
        description: 'Global ID of a work item that should be placed before the work item.',
        prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id)&.model_id }

      argument :move_after_id,
        ::Types::GlobalIDType[::WorkItem],
        required: false,
        description: 'Global ID of a work item that should be placed after the work item.',
        prepare: ->(id, _ctx) { GitlabSchema.parse_gid(id)&.model_id }

      field :work_item,
        ::Types::WorkItemType,
        null: true,
        description: 'Work item after mutation.'

      authorize :update_work_item

      def ready?(**args)
        return super if args.slice(:move_after_id, :move_before_id).compact.present?

        raise Gitlab::Graphql::Errors::ArgumentError,
          'At least one of move_before_id and move_after_id are required'
      end

      def resolve(**args)
        work_item = authorized_find!(id: args[:id])

        ::WorkItems::ReorderService.new(
          current_user: current_user,
          params: args.slice(:move_before_id, :move_after_id)
        ).execute(work_item).payload
      end
    end
  end
end
