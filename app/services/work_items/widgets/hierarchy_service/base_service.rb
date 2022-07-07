# frozen_string_literal: true

module WorkItems
  module Widgets
    module HierarchyService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def update_work_item_parent(parent_id)
          begin
            parent = ::WorkItem.find(parent_id)
          rescue ActiveRecord::RecordNotFound
            return parent_not_found_error(parent_id)
          end

          ::WorkItems::ParentLinks::CreateService
            .new(parent, current_user, { target_issuable: widget.work_item })
            .execute
        end

        def update_work_item_children(children_ids)
          ::WorkItems::ParentLinks::CreateService
            .new(widget.work_item, current_user, { issuable_references: children_ids })
            .execute
        end

        def parent_not_found_error(id)
          error(_('No Work Item found with ID: %{id}.' % { id: id }))
        end
      end
    end
  end
end
