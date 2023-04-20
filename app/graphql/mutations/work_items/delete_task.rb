# frozen_string_literal: true

module Mutations
  module WorkItems
    class DeleteTask < BaseMutation
      graphql_name 'WorkItemDeleteTask'

      description "Deletes a task in a work item's description."

      authorize :update_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the work item.'
      argument :lock_version, GraphQL::Types::Int,
               required: true,
               description: 'Current lock version of the work item containing the task in the description.'
      argument :task_data, ::Types::WorkItems::DeletedTaskInputType,
               required: true,
               description: 'Arguments necessary to delete a task from a work item\'s description.',
               prepare: ->(attributes, _ctx) { attributes.to_h }

      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Updated work item.'

      def resolve(id:, lock_version:, task_data:)
        work_item = authorized_find!(id: id)
        task_data[:task] = authorized_find_task!(task_data[:id])

        result = ::WorkItems::DeleteTaskService.new(
          work_item: work_item,
          current_user: current_user,
          lock_version: lock_version,
          task_params: task_data
        ).execute

        response = { errors: result.errors }
        response[:work_item] = work_item if result.success?

        response
      end

      private

      def authorized_find_task!(task_id)
        task = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(task_id))

        if current_user.can?(:delete_work_item, task)
          task
        else
          # Fail early if user cannot delete task
          raise_resource_not_available_error!
        end
      end
    end
  end
end
