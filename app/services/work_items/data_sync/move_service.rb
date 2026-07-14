# frozen_string_literal: true

module WorkItems
  module DataSync
    class MoveService < ::WorkItems::DataSync::BaseService
      # `skip_work_item_type_check` is an explicit keyword (not a params key) so
      # user-supplied params can never enable the bypass. Used by internal
      # hierarchy moves to skip the `supports_move_and_clone?` gate.
      def initialize(work_item:, target_namespace:, current_user: nil, params: {}, skip_work_item_type_check: false)
        @skip_work_item_type_check = skip_work_item_type_check
        super(
          work_item: work_item, target_namespace: target_namespace,
          current_user: current_user, params: params
        )
      end

      class << self
        def transaction_callback(new_work_item, original_work_item, current_user)
          original_work_item.update(moved_to: new_work_item)

          close_original_work_item(current_user, new_work_item, original_work_item)
          move_system_notes(current_user, new_work_item, original_work_item)
          track_work_item_move(original_work_item, current_user)
        end

        private

        def move_system_notes(current_user, new_work_item, original_work_item)
          SystemNoteService.noteable_moved(
            new_work_item,
            new_work_item.resource_parent,
            original_work_item,
            current_user,
            direction: :from
          )

          SystemNoteService.noteable_moved(
            original_work_item,
            original_work_item.resource_parent,
            new_work_item,
            current_user,
            direction: :to
          )
        end

        def close_original_work_item(current_user, new_work_item, original_work_item)
          context = { original: original_work_item, user: current_user }

          # We need this because move work item is supposed to work with epics and for EpicWorkItem
          # Issues::CloseService. Because this is being run within a transaction,
          # we are delaying the close operation until after commit.
          new_work_item.run_after_commit_or_now do
            close_service = ::Issues::CloseService.new(
              container: context[:original].namespace, current_user: context[:user]
            )
            close_service.execute(context[:original], notifications: false, system_note: true)
          end
        end

        def track_work_item_move(work_item, current_user)
          Gitlab::WorkItems::Instrumentation::TrackingService.new(
            work_item: work_item,
            current_user: current_user,
            event: Gitlab::WorkItems::Instrumentation::EventActions::MOVE
          ).execute
        end
      end

      private

      def verify_work_item_action_permission
        verify_can_move_work_item(work_item, target_namespace)
      end

      def data_sync_action
        return success({ work_item: work_item }) if same_namespace?(target_namespace, work_item)

        move_work_item
      end

      def verify_can_move_work_item(work_item, target_namespace)
        unless work_item.can_move?(current_user, target_namespace)
          error_message = s_('MoveWorkItem|Unable to move. You have insufficient permissions.')

          return error(error_message, :unprocessable_entity)
        end

        unless work_item.namespace.instance_of?(target_namespace.class)
          error_message = s_('MoveWorkItem|Unable to move. Moving across projects and groups is not supported.')

          return error(error_message, :unprocessable_entity)
        end

        unless work_item.supports_move_and_clone? || @skip_work_item_type_check
          error_message = format(s_('MoveWorkItem|Unable to move. Moving \'%{work_item_type}\' is not supported.'),
            { work_item_type: work_item.work_item_type.name })

          return error(error_message, :unprocessable_entity)
        end

        if target_namespace.deletion_in_progress_or_scheduled_in_hierarchy_chain?
          error_message = s_('MoveWorkItem|Unable to move. Target namespace is pending deletion.')

          return error(error_message, :unprocessable_entity)
        end

        success({})
      end

      # Skip resolution for same-namespace moves (conversion is a no-op there).
      def skip_target_work_item_type_resolution?
        same_namespace?(target_namespace, work_item)
      end

      # Internal hierarchy moves fully control the resulting type, so discard any
      # caller-supplied id. The source type is still verified at the destination
      # because the target may be on a different top-level group.
      def ignore_target_work_item_type_id_param?
        @skip_work_item_type_check
      end

      def same_namespace?(target_namespace, work_item)
        work_item.namespace_id == target_namespace.id
      end

      def move_work_item
        create_response = WorkItems::DataSync::Handlers::CopyDataHandler.new(
          work_item: work_item,
          target_namespace: target_namespace,
          current_user: current_user,
          target_work_item_type: resolved_target_work_item_type,
          params: params.merge(operation: :move),
          overwritten_params: {
            moved_issue: true
          }
        ).execute

        return create_response unless create_response.success? && create_response[:work_item].present?

        # this service is based on Issues::CloseService#execute, which does not provide a clear return, so we'll skip
        # handling it for now. This will be moved to a cleanup service that would be more result oriented where we can
        # handle the service response status
        WorkItems::DataSync::Handlers::CleanupDataHandler.new(
          work_item: work_item, current_user: current_user, params: params
        ).execute

        create_response
      end

      def target_work_item_type_not_available_error_message
        s_("MoveWorkItem|Unable to move. The selected work item type is not available in the target namespace.")
      end
    end
  end
end
