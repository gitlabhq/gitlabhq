# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Assignees < Base
        def after_create
          return unless target_work_item.get_widget(:assignees)

          work_item.issue_assignees.each_batch(column: :user_id, of: BATCH_SIZE) do |assignees_batch|
            ::IssueAssignee.insert_all(
              new_work_item_assignees(assignees_batch.map(&:user_id)), unique_by: [:issue_id, :user_id]
            )
          end
        end

        def post_move_cleanup
          work_item.issue_assignees.each_batch(column: :user_id, of: BATCH_SIZE) do |assignees_batch|
            assignees_batch.delete_all
          end
        end

        private

        def new_work_item_assignees(assignee_ids)
          assignee_ids.map do |user_id|
            {
              issue_id: target_work_item.id,
              user_id: user_id
            }
          end
        end
      end
    end
  end
end
