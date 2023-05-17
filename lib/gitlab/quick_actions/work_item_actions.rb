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
        condition do
          quick_action_target&.project&.work_items_mvc_2_feature_flag_enabled?
        end
        params 'Task | Objective | Key Result | Issue'
        command :type do |type_name|
          work_item_type = ::WorkItems::Type.find_by_name(type_name)
          errors = validate_type(work_item_type)

          if errors.present?
            @execution_message[:type] = errors
          else
            @updates[:issue_type] = work_item_type.base_type
            @updates[:work_item_type] = work_item_type
            @execution_message[:type] = _('Type changed successfully.')
          end
        end
      end

      private

      def validate_type(type)
        return type_error(:not_found) unless type.present?
        return type_error(:same_type) if quick_action_target.work_item_type == type
        return type_error(:forbidden) unless current_user.can?(:"create_#{type.base_type}", quick_action_target)

        nil
      end

      def type_error(reason)
        message = {
          not_found: 'Provided type is not supported',
          same_type: 'Types are the same',
          forbidden: 'You have insufficient permissions'
        }.freeze

        format(_("Failed to convert this work item: %{reason}."), { reason: message[reason] })
      end
    end
  end
end
