# frozen_string_literal: true

module WorkItems
  module Widgets
    module HierarchyService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def handle_hierarchy_changes(params)
          return feature_flag_error unless feature_flag_enabled?
          return incompatible_args_error if incompatible_args?(params)

          update_hierarchy(params)
        end

        def update_hierarchy(params)
          parent_id = params.delete(:parent_id)
          children_ids = params.delete(:children_ids)

          return update_work_item_parent(parent_id) if parent_id

          update_work_item_children(children_ids) if children_ids
        end

        def feature_flag_enabled?
          Feature.enabled?(:work_items_hierarchy, widget.work_item&.project)
        end

        def incompatible_args?(params)
          params[:parent_id] && params[:children_ids]
        end

        def feature_flag_error
          error(_('`work_items_hierarchy` feature flag disabled for this project'))
        end

        def incompatible_args_error
          error(_('A Work Item can be a parent or a child, but not both.'))
        end

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
