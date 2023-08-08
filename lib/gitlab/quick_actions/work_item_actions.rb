# frozen_string_literal: true

module Gitlab
  module QuickActions
    module WorkItemActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        desc { _('Change work item type') }
        explanation do |target_type|
          format(_("Converts work item to %{type}. Widgets not supported in new type are removed."), type: target_type)
        end
        types WorkItem
        params 'Task | Objective | Key Result | Issue'
        command :type do |type_name|
          @execution_message[:type] = update_type(type_name, :type)
        end

        desc { _('Promote work item') }
        explanation do |type_name|
          format(_("Promotes work item to %{type}."), type: type_name)
        end
        types WorkItem
        params 'issue | objective'
        condition { supports_promotion? }
        command :promote_to do |type_name|
          @execution_message[:promote_to] = update_type(type_name, :promote_to)
        end
      end

      private

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def update_type(type_name, command)
        new_type = ::WorkItems::Type.find_by_name(type_name.titleize)
        error_message = command == :type ? validate_type(new_type) : validate_promote_to(new_type)
        return error_message if error_message.present?

        @updates[:issue_type] = new_type.base_type
        @updates[:work_item_type] = new_type

        success_msg[command]
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def validate_type(type)
        return error_msg(:not_found) unless type.present?
        return error_msg(:same_type) if quick_action_target.work_item_type == type
        return error_msg(:forbidden) unless current_user.can?(:"create_#{type.base_type}", quick_action_target)

        nil
      end

      def validate_promote_to(type)
        return error_msg(:not_found, action: 'promote') unless type && supports_promote_to?(type.name)
        return if current_user.can?(:"create_#{type.base_type}", quick_action_target)

        error_msg(:forbidden, action: 'promote')
      end

      def current_type
        quick_action_target.work_item_type
      end

      def supports_promotion?
        current_type.base_type.in?(promote_to_map.keys)
      end

      def supports_promote_to?(type_name)
        type_name == promote_to_map[current_type.base_type]
      end

      def promote_to_map
        { issue: 'Incident', task: 'Issue' }.with_indifferent_access
      end

      def error_msg(reason, action: 'convert')
        message = {
          not_found: 'Provided type is not supported',
          same_type: 'Types are the same',
          forbidden: 'You have insufficient permissions'
        }.freeze

        format(_("Failed to %{action} this work item: %{reason}."), { action: action, reason: message[reason] })
      end

      def success_msg
        {
          type: _('Type changed successfully.'),
          promote_to: _("Work item promoted successfully.")
        }
      end
    end
  end
end
