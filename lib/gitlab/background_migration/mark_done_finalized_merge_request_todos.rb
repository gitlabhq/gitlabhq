# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MarkDoneFinalizedMergeRequestTodos < BatchedMigrationJob
      cursor :id
      operation_name :mark_done_finalized_merge_request_todos
      feature_category :notifications

      # Values of TodoService::RESOLVE_ON_MR_FINALIZED_ACTIONS:
      # ASSIGNED, APPROVAL_REQUIRED, REVIEW_REQUESTED, ADDED_APPROVER.
      RESOLVABLE_ACTIONS = [1, 5, 9, 13].freeze
      # Issuable::STATE_ID_MAP values for closed and merged.
      FINALIZED_MR_STATES = [2, 3].freeze
      # Todo#resolved_by_action enum value for :system_done (app/models/todo.rb:
      # `system_done: 0`). Used as a literal because the update runs via
      # update_all and never loads the Todo model or its enum.
      SYSTEM_DONE = 0

      def perform
        each_sub_batch do |sub_batch|
          matching = sub_batch
            .where(action: RESOLVABLE_ACTIONS, state: 'pending', target_type: 'MergeRequest')
            .joins('INNER JOIN merge_requests ON merge_requests.id = todos.target_id')
            .where(merge_requests: { state_id: FINALIZED_MR_STATES })

          user_ids = matching.pluck('todos.user_id').uniq
          next if user_ids.empty?

          matching.update_all(
            state: 'done',
            resolved_by_action: SYSTEM_DONE,
            snoozed_until: nil,
            updated_at: Time.current
          )

          invalidate_pending_count_cache(user_ids)
        end
      end

      private

      def invalidate_pending_count_cache(user_ids)
        keys = user_ids.map { |user_id| ['users', user_id, 'todos_pending_count'] }
        Rails.cache.delete_multi(keys)
      end
    end
  end
end
