# frozen_string_literal: true

module Mutations
  module WorkItems
    class UpdateTask < BaseMutation
      graphql_name 'WorkItemUpdateTask'
      description "Updates a work item's task by Global ID." \
                  " Available only when feature flag `work_items` is enabled. The feature is experimental and is" \
                  " subject to change without notice."

      include Mutations::SpamProtection

      authorize :read_work_item

      argument :id, ::Types::GlobalIDType[::WorkItem],
               required: true,
               description: 'Global ID of the work item.'
      argument :task_data, ::Types::WorkItems::UpdatedTaskInputType,
               required: true,
               description: 'Arguments necessary to update a task.'

      field :task, Types::WorkItemType,
            null: true,
            description: 'Updated task.'
      field :work_item, Types::WorkItemType,
            null: true,
            description: 'Updated work item.'

      def resolve(id:, task_data:)
        task_data_hash = task_data.to_h
        work_item = authorized_find!(id: id)
        task = authorized_find_task!(task_data_hash[:id])

        unless work_item.project.work_items_feature_flag_enabled?
          return { errors: ['`work_items` feature flag disabled for this project'] }
        end

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        ::WorkItems::UpdateService.new(
          project: task.project,
          current_user: current_user,
          params: task_data_hash.except(:id),
          spam_params: spam_params
        ).execute(task)

        check_spam_action_response!(task)

        response = { errors: errors_on_object(task) }

        if task.valid?
          work_item.expire_etag_cache

          response.merge(work_item: work_item, task: task)
        else
          response
        end
      end

      private

      def authorized_find_task!(task_id)
        task = task_id.find

        if current_user.can?(:update_work_item, task)
          task
        else
          # Fail early if user cannot update task
          raise_resource_not_available_error!
        end
      end

      def find_object(id:)
        id.find
      end
    end
  end
end
