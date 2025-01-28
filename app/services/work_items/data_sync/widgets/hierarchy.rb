# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Hierarchy < Base
        ALLOWED_PARAMS = %i[parent_work_item_id].freeze

        def after_save_commit
          return unless target_work_item.get_widget(:hierarchy)

          handle_parent

          # we only handle child items for `move` functionality, `clone` does not copy child items.
          return unless params[:operation] == :move

          handle_children
        end

        # Nothing to delete for children as we relink existing child links
        # to the new parent in `relink_children_to_target_work_item`
        def post_move_cleanup
          return unless work_item.parent_link.present?

          work_item.parent_link.destroy!
        end

        private

        def handle_parent
          return unless work_item.parent_link.present?

          parent_link_attributes = work_item.parent_link.attributes.except("id").tap do |attributes|
            attributes["work_item_id"] = target_work_item.id
            attributes["namespace_id"] = target_work_item.namespace_id
            attributes["work_item_parent_id"] = params[:parent_work_item_id] if params[:parent_work_item_id].present?
          end

          WorkItems::ParentLink.create!(parent_link_attributes)
        end

        def handle_children
          # Relink child items to the new work item first. This will be used for any work item type other than issue.
          # For issue work item type we will relink child items, but then also actually move the child items(tasks) to
          # the destination namespace. This is to keep feature parity with existing move functionality on issue.
          relink_children_to_target_work_item

          # We only support moving child items for the issue work item type for now
          move_children if work_item.work_item_type.issue?
        end

        def relink_children_to_target_work_item
          work_item.child_links.each_batch(of: BATCH_SIZE) do |child_links_batch|
            # We need to upsert because an work item cannot have multiple parents,
            # so we cannot create a "copy" parent link record where same child work item
            # points to the target work item as the new parent
            WorkItems::ParentLink.upsert_all(new_work_item_child_link(child_links_batch), unique_by: :work_item_id)
          end
        end

        def new_work_item_child_link(child_links_batch)
          child_links_batch.map do |child_link|
            child_link.attributes.except("id").tap do |attrs|
              attrs['work_item_parent_id'] = target_work_item.id
            end
          end
        end

        def move_children
          # Reload as the child_links association was just changed by relinking child items
          # in `relink_children_to_target_work_item`
          target_work_item.reset

          # We iterate over "new work item" child links now, because we have relinked child items from moved work item
          # to the new work item in `relink_children_to_target_work_item`.
          target_work_item.child_links.each do |link|
            execution_arguments = { parent_work_item_id: target_work_item.id, skip_work_item_type_check: true }

            # This is going to be moved to an async worker. This is planned as a follow-up up iteration for a bunch of
            # other work item association data. The async implementation for move will be tracked in:
            # https://gitlab.com/groups/gitlab-org/-/epics/15934
            ::WorkItems::DataSync::MoveService.new(
              work_item: link.work_item, target_namespace: target_work_item.namespace, current_user: current_user
            ).execute(**execution_arguments)
          end
        end
      end
    end
  end
end

WorkItems::DataSync::Widgets::Hierarchy.prepend_mod
