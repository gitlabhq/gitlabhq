# frozen_string_literal: true

module WorkItems
  module Widgets
    module HierarchyService
      class UpdateService < WorkItems::Widgets::HierarchyService::BaseService
        def before_update_in_transaction(params:)
          return unless params.present?

          result = handle_hierarchy_changes(params)

          raise WidgetError, result[:message] if result[:status] == :error
        end

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
      end
    end
  end
end
