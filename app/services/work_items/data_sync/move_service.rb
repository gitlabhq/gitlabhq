# frozen_string_literal: true

module WorkItems
  module DataSync
    class MoveService < ::WorkItems::DataSync::BaseService
      MoveError = Class.new(StandardError)

      private

      def verify_work_item_action_permission!
        verify_can_move_work_item!(work_item, target_namespace)
      end

      def data_sync_action
        new_work_item = move_work_item

        # this may need to be moved inside `BaseCopyDataService` so that this would be the first system note after
        # move action started, followed by some other system notes related to which data is removed, replaced, changed
        # etc during the move operation.
        move_system_notes(new_work_item)

        new_work_item
      end

      def verify_can_move_work_item!(work_item, target_namespace)
        unless work_item.namespace.instance_of?(target_namespace.class)
          raise MoveError, s_('MoveWorkItem|Cannot move work item between Projects and Groups.')
        end

        unless work_item.supports_move_and_clone?
          raise MoveError, format(s_('MoveWorkItem|Cannot move work items of \'%{issue_type}\' type.'), {
            issue_type: work_item.work_item_type.name
          })
        end

        unless work_item.can_move?(current_user, target_namespace)
          raise MoveError, s_('MoveWorkItem|Cannot move work item due to insufficient permissions!')
        end

        if target_namespace.pending_delete? # rubocop:disable Style/GuardClause -- does not read right with other checks above
          raise MoveError, s_('MoveWorkItem|Cannot move work item to target namespace as it is pending deletion.')
        end
      end

      def move_work_item
        create_result = WorkItems::DataSync::Handlers::CopyDataHandler.new(
          work_item: work_item,
          target_namespace: target_namespace,
          current_user: current_user,
          target_work_item_type: work_item.work_item_type,
          params: params,
          overwritten_params: {
            moved_issue: true
          }
        ).execute

        new_work_item = create_result[:work_item]

        raise MoveError, create_result.errors.join(', ') if create_result.error? && new_work_item.blank?

        WorkItems::DataSync::Handlers::CleanupDataHandler.new(
          work_item: work_item, current_user: current_user, params: params
        ).execute

        new_work_item
      end

      def move_system_notes(new_work_item)
        SystemNoteService.noteable_moved(
          new_work_item,
          new_work_item.project,
          work_item,
          current_user,
          direction: :from
        )

        SystemNoteService.noteable_moved(
          work_item,
          work_item.project,
          new_work_item,
          current_user,
          direction: :to
        )
      end
    end
  end
end
