# frozen_string_literal: true

module Gitlab
  module QuickActions
    module WorkItemActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        desc { _('Change item type') }
        explanation do |target_type|
          format(_("Converts item to %{type}. Widgets not supported in new type are removed."), type: target_type)
        end
        types WorkItem
        params 'Task | Objective | Key Result | Issue'
        condition { type_change_allowed? }
        command :type do |type_name|
          @execution_message[:type] = update_type(type_name, :type)
        end

        desc { _('Promote item') }
        explanation do |type_name|
          format(_("Promotes item to %{type}."), type: type_name)
        end
        types WorkItem
        params do
          promote_to_map[current_type.base_type].join(' | ')
        end
        condition { supports_promotion? }
        command :promote_to do |type_name|
          @execution_message[:promote_to] = update_type(type_name, :promote_to)
        end

        desc { _('Set parent item') }
        explanation do |parent_param|
          format(_("Set %{parent_ref} as this item's parent item."), parent_ref: parent_param)
        end
        types WorkItem, Issue
        params 'Parent item\'s #IID, reference, or URL'
        condition do
          quick_action_target.supports_parent? && can_admin_set_relation?
        end
        conditional_aliases_autocompletion :epic do
          show_epic_alias?
        end
        command :set_parent, :epic do |parent_param|
          if quick_action_target.instance_of?(WorkItem)
            handle_set_parent(parent_param)
          elsif quick_action_target.instance_of?(Issue)
            handle_set_epic(parent_param)
          end
        end

        desc { _('Remove parent item') }
        explanation do
          format(
            _("Remove %{parent_ref} as this item's parent item."),
            parent_ref: work_item_parent.to_reference(quick_action_target)
          )
        end
        types WorkItem
        condition { work_item_parent.present? && can_admin_set_relation? }
        command :remove_parent do
          @updates[:remove_parent] = true
          @execution_message[:remove_parent] = success_msg[:remove_parent]
        end

        desc { _('Add child items') }
        explanation do |child_param|
          format(_("Add %{child_ref} as a child item."), child_ref: child_param)
        end
        types WorkItem
        params 'Child items\' #IIDs, references, or URLs'
        condition { supports_children? && can_admin_link? }
        command :add_child do |child_param|
          @updates[:add_child] = extract_work_items(child_param)
          @execution_message[:add_child] = success_msg[:add_child]
        end

        desc { _('Remove child item') }
        explanation do |child_param|
          format(_("Remove %{child_ref} as a child item."), child_ref: child_param)
        end
        types WorkItem
        params 'Child item\'s #IID, reference, or URL'
        condition { has_children? && can_admin_link? }
        command :remove_child do |child_param|
          @updates[:remove_child] = extract_work_items(child_param).first
          @execution_message[:remove_child] = success_msg[:remove_child]
        end
      end

      private

      def update_type(type_name, command)
        new_type = ::WorkItems::Type.find_by_name(type_name.titleize)
        error_message = command == :type ? validate_type(new_type) : validate_promote_to(new_type)
        return error_message if error_message.present?

        apply_type_commands(new_type, command)
      end

      def validate_type(type)
        return error_msg(:not_found) unless type.present?
        return error_msg(:same_type) if quick_action_target.work_item_type == type
        return error_msg(:forbidden) unless current_user.can?(:"create_#{type.base_type}", quick_action_target)

        nil
      end

      def extract_work_items(params)
        return if params.nil?

        issues = extract_references(params, :issue)
        work_items = extract_references(params, :work_item)

        ::WorkItem.id_in(issues) + work_items
      end

      def validate_promote_to(type)
        return error_msg(:not_found, action: 'promote') unless type && supports_promote_to?(type.name)
        return error_msg(:forbidden, action: 'promote') unless promotion_allowed?
        return if current_user.can?(:"create_#{type.base_type}", quick_action_target)

        error_msg(:forbidden, action: 'promote')
      end

      def current_type
        quick_action_target.work_item_type
      end

      def supports_promotion?
        current_type.base_type.in?(promote_to_map.keys)
      end

      def promotion_allowed?
        current_user.can?(:update_work_item, quick_action_target)
      end

      def type_change_allowed?
        true
      end

      def supports_promote_to?(type_name)
        promote_to_map[current_type.base_type].include?(type_name)
      end

      def promote_to_map
        { issue: ['Incident'], task: ['Issue'] }.with_indifferent_access
      end

      def error_msg(reason, action: 'convert')
        message = {
          not_found: 'Provided type is not supported',
          forbidden: 'You have insufficient permissions',
          same_type: 'Types are the same'
        }.freeze

        format(_("Failed to %{action} this work item: %{reason}."), { action: action, reason: message[reason] })
      end

      def success_msg
        {
          type: _('Type changed successfully.'),
          promote_to: _("Promoted successfully."),
          set_parent: _('Parent item set successfully.'),
          remove_parent: _('Parent item removed successfully.'),
          add_child: _('Child items added successfully.'),
          remove_child: _('Child item removed successfully.')
        }
      end

      def work_item_parent
        quick_action_target.work_item_parent
      end

      def supports_children?
        ::WorkItems::HierarchyRestriction.find_by_parent_type_id(quick_action_target.work_item_type_id).present?
      end

      def has_children?
        supports_children? && quick_action_target.work_item_children.present?
      end

      def can_admin_link?
        current_user.can?(:admin_issue_link, quick_action_target)
      end

      def can_admin_set_relation?
        current_user.can?(:admin_issue_relation, quick_action_target)
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- @updates is already defined and part of
      # Gitlab::QuickActions::Dsl implementation
      def apply_type_commands(new_type, command)
        @updates[:issue_type] = new_type.base_type
        @updates[:work_item_type] = new_type

        success_msg[command]
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      # overridden in EE
      def handle_set_epic(parent_param); end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- @updates is already defined and part of
      # Gitlab::QuickActions::Dsl implementation
      def handle_set_parent(parent_param)
        parent = extract_work_items(parent_param).first
        child = quick_action_target

        message =
          if parent && current_user.can?(:read_work_item, parent)
            if child&.work_item_parent == parent
              format(_('Work item %{work_item_reference} has already been added to parent %{parent_reference}.'),
                work_item_reference: child&.to_reference, parent_reference: parent.to_reference)
            elsif parent.confidential? && !child&.confidential?
              _("Cannot assign a confidential parent to a non-confidential work item. Make the work item " \
                "confidential and try again")
            elsif ::WorkItems::HierarchyRestriction.find_by_parent_type_id_and_child_type_id(parent.work_item_type_id,
              child&.work_item_type_id).nil?
              _("Cannot assign this work item type to parent type")
            else
              @updates[:set_parent] = parent
              success_msg[:set_parent]
            end
          else
            _("This parent does not exist or you don't have sufficient permission.")
          end

        @execution_message[:set_parent] = message
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      # overridden in EE
      def show_epic_alias?; end
    end
  end
end
