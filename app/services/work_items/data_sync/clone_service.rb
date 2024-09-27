# frozen_string_literal: true

module WorkItems
  module DataSync
    class CloneService < ::WorkItems::DataSync::BaseService
      CloneError = Class.new(StandardError)

      private

      def verify_work_item_action_permission!
        verify_can_clone_work_item!(work_item, target_namespace)
      end

      def data_sync_action
        new_work_item = clone_work_item

        # this may need to be moved inside `BaseCopyDataService` so that this would be the first system note after
        # clone action started, followed by some other system notes related to data that was not copied over for
        # various reasons, e.g. labels or milestone not being copied/set due to not being found in the target namespace
        clone_system_notes(new_work_item)

        new_work_item
      end

      def verify_can_clone_work_item!(work_item, target_namespace)
        unless work_item.namespace.instance_of?(target_namespace.class)
          raise CloneError, s_('CloneWorkItem|Cannot clone work item between Projects and Groups.')
        end

        unless work_item.supports_move_and_clone?
          raise CloneError, format(s_('CloneWorkItem|Cannot clone work items of \'%{work_item_type}\' type.'), {
            work_item_type: work_item.work_item_type.name
          })
        end

        unless work_item.can_clone?(current_user, target_namespace)
          raise CloneError, s_('CloneWorkItem|Cannot clone work item due to insufficient permissions!')
        end

        if target_namespace.pending_delete? # rubocop:disable Style/GuardClause -- does not read right with other checks above
          raise CloneError, s_('CloneWorkItem|Cannot clone work item to target namespace as it is pending deletion.')
        end
      end

      def clone_work_item
        # todo specify which widgets are to be copied during clone as not everything is copied:
        #   e.g. child items, linked items, development?
        create_result = WorkItems::DataSync::Handlers::CopyDataHandler.new(
          work_item: work_item,
          target_namespace: target_namespace,
          current_user: current_user,
          target_work_item_type: work_item.work_item_type,
          params: params,
          overwritten_params: {
            author: current_user, created_at: nil, updated_at: nil
          }
        ).execute

        new_work_item = create_result[:work_item]

        raise CloneError, create_result.errors.join(', ') if create_result.error? && new_work_item.blank?

        new_work_item
      end

      def clone_system_notes(new_work_item)
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
  end
end
