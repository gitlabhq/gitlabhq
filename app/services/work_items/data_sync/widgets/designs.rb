# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Designs < Base
        def after_save_commit
          return unless target_work_item.get_widget(:designs)
          return unless work_item.designs.exists?

          if cross_organization?
            log_error("Cannot copy designs across organizations")
            return
          end

          unless user_can_copy?
            log_error("User cannot copy designs to work item")
            return
          end

          target_design_collection = target_work_item.design_collection

          unless target_design_collection.can_start_copy?
            log_error("Target design collection copy state must be `ready`")
            return
          end

          target_design_collection.start_copy!

          DesignManagement::CopyDesignCollectionWorker.perform_async(current_user.id, work_item.id, target_work_item.id)
        end

        def post_move_cleanup
          cleanup_designs
          cleanup_design_versions
        end

        private

        # Design repositories live on the container's cell-local Gitaly storage and
        # cannot be copied to another cell, so designs never cross organizations.
        def cross_organization?
          return false unless Feature.enabled?(:prevent_cross_organization_work_item_actions, work_item.root_ancestor)

          !work_item.same_organization_as?(target_work_item)
        end

        def user_can_copy?
          current_user.can?(:read_design, work_item) && current_user.can?(:admin_issue, target_work_item)
        end

        # cleanup all designs for the work item, we use destroy as there are the notes, user_mentions and events
        # associations that have `dependent: delete_all` and they need to be deleted too, after they are being copied
        # to the target work item
        def cleanup_designs
          work_item.designs.each_batch(of: BATCH_SIZE) do |designs|
            designs.destroy_all # rubocop:disable Cop/DestroyAll -- need to destroy all designs with associated records
          end
        end

        # cleanup all design versions for the work item, we can safely use delete_all as there are no associated
        # records or callbacks
        def cleanup_design_versions
          work_item.design_versions.each_batch(of: BATCH_SIZE) do |design_versions|
            design_versions.delete_all
          end
        end
      end
    end
  end
end
