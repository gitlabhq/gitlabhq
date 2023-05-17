# frozen_string_literal: true

module WorkItems
  module Widgets
    module HierarchyService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def handle_hierarchy_changes(params)
          return incompatible_args_error if incompatible_args?(params)

          if params.key?(:parent)
            update_work_item_parent(params.delete(:parent))
          elsif params.key?(:children)
            update_work_item_children(params.delete(:children))
          else
            invalid_args_error(params)
          end
        end

        def update_work_item_parent(parent)
          if parent.nil?
            remove_parent
          else
            set_parent(parent)
          end
        end

        def set_parent(parent)
          ::WorkItems::ParentLinks::CreateService
            .new(parent, current_user, { target_issuable: work_item })
            .execute
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def remove_parent
          link = ::WorkItems::ParentLink.find_by(work_item: work_item)
          return success unless link.present?

          ::WorkItems::ParentLinks::DestroyService.new(link, current_user).execute
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def update_work_item_children(children)
          ::WorkItems::ParentLinks::CreateService
            .new(work_item, current_user, { issuable_references: children })
            .execute
        end

        def incompatible_args?(params)
          params[:children] && params[:parent]
        end

        def incompatible_args_error
          error(_('A Work Item can be a parent or a child, but not both.'))
        end

        def invalid_args_error(params)
          error(_("One or more arguments are invalid: %{args}." % { args: params.keys.to_sentence }))
        end

        def service_response!(result)
          work_item.reload_work_item_parent
          work_item.work_item_children.reset

          super
        end
      end
    end
  end
end
