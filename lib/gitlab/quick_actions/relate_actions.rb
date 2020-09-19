# frozen_string_literal: true

module Gitlab
  module QuickActions
    module RelateActions
      extend ActiveSupport::Concern
      include ::Gitlab::QuickActions::Dsl

      included do
        desc _('Mark this issue as related to another issue')
        explanation do |related_reference|
          _('Marks this issue as related to %{issue_ref}.') % { issue_ref: related_reference }
        end
        execution_message do |related_reference|
          _('Marked this issue as related to %{issue_ref}.') % { issue_ref: related_reference }
        end
        params '#issue'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :relate do |related_param|
          IssueLinks::CreateService.new(quick_action_target, current_user, { issuable_references: [related_param] }).execute
        end
      end
    end
  end
end
