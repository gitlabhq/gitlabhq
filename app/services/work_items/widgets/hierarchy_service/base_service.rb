# frozen_string_literal: true

module WorkItems
  module Widgets
    module HierarchyService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def handle_hierarchy_changes(params)
          return incompatible_args_error if params.slice(*mutually_exclusive_args).size > 1

          if params.key?(:parent)
            update_work_item_parent(params.delete(:parent))
          elsif params.key?(:children)
            update_work_item_children(params.delete(:children))
          elsif params.key?(:remove_child)
            remove_child(params.delete(:remove_child))
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
          service_response = ::WorkItems::ParentLinks::CreateService
            .new(parent, current_user, { target_issuable: work_item })
            .execute

          # Reference the parent instead because the error is returned in the child context
          if service_response[:status] == :error
            service_response[:message].sub!(/#.* cannot be added/, "#{parent.to_reference} cannot be added")
          end

          service_response
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def remove_parent_link(child)
          link = ::WorkItems::ParentLink.find_by(work_item: child)
          return success unless link.present?

          ::WorkItems::ParentLinks::DestroyService.new(link, current_user).execute
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def remove_parent
          remove_parent_link(work_item)
        end

        def remove_child(child)
          remove_parent_link(child)
        end

        def update_work_item_children(children)
          ::WorkItems::ParentLinks::CreateService
            .new(work_item, current_user, { issuable_references: children })
            .execute
        end

        def mutually_exclusive_args
          [:children, :parent, :remove_child]
        end

        def incompatible_args_error
          error(format(
            _("One and only one of %{params} is required"),
            params: mutually_exclusive_args.to_sentence(last_word_connector: ' or ')
          ))
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
