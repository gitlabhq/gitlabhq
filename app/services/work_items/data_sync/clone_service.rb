# frozen_string_literal: true

module WorkItems
  module DataSync
    class CloneService < ::WorkItems::DataSync::BaseService
      class << self
        def transaction_callback(new_work_item, work_item, current_user)
          clone_system_notes(current_user, new_work_item, work_item)
        end

        private

        def clone_system_notes(current_user, new_work_item, work_item)
          SystemNoteService.noteable_cloned(
            new_work_item,
            new_work_item.project,
            work_item,
            current_user,
            direction: :from,
            created_at: new_work_item.created_at
          )

          SystemNoteService.noteable_cloned(
            work_item,
            work_item.project,
            new_work_item,
            current_user,
            direction: :to
          )
        end
      end

      private

      def verify_work_item_action_permission
        verify_can_clone_work_item(work_item, target_namespace)
      end

      def data_sync_action
        clone_work_item
      end

      def verify_can_clone_work_item(work_item, target_namespace)
        unless work_item.namespace.instance_of?(target_namespace.class)
          error_message = s_('CloneWorkItem|Cannot clone work item between Projects and Groups.')

          return error(error_message, :unprocessable_entity)
        end

        unless work_item.supports_move_and_clone?
          error_message = format(s_('CloneWorkItem|Cannot clone work items of \'%{work_item_type}\' type.'),
            { work_item_type: work_item.work_item_type.name })

          return error(error_message, :unprocessable_entity)
        end

        unless work_item.can_clone?(current_user, target_namespace)
          error_message = s_('CloneWorkItem|Cannot clone work item due to insufficient permissions.')

          return error(error_message, :unprocessable_entity)
        end

        if target_namespace.pending_delete?
          error_message = s_('CloneWorkItem|Cannot clone work item to target namespace as it is pending deletion.')

          return error(error_message, :unprocessable_entity)
        end

        success({})
      end

      def clone_work_item
        # Each widget is responsible for handling the copying of data during clone. Some widgets data is copied some
        # is not.
        # todo: add a user facing documentation which data is copied during clone.
        WorkItems::DataSync::Handlers::CopyDataHandler.new(
          work_item: work_item,
          target_namespace: target_namespace,
          current_user: current_user,
          target_work_item_type: work_item.work_item_type,
          params: params.merge(operation: :clone),
          overwritten_params: {
            author: current_user, created_at: nil, updated_by: current_user, updated_at: nil,
            last_edited_at: nil, last_edited_by: nil, closed_at: nil, closed_by: nil,
            duplicated_to_id: nil, moved_to_id: nil, promoted_to_epic_id: nil, external_key: nil,
            upvotes_count: 0, blocking_issues_count: 0,
            state_id: WorkItem.available_states[:opened]
          }
        ).execute
      end
    end
  end
end
