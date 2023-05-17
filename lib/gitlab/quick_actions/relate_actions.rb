# frozen_string_literal: true

module Gitlab
  module QuickActions
    module RelateActions
      extend ActiveSupport::Concern
      include ::Gitlab::QuickActions::Dsl

      included do
        desc { _('Mark this issue as related to another issue') }
        explanation do |target_issues|
          _('Marks this issue as related to %{issue_ref}.') % { issue_ref: target_issues.to_sentence }
        end
        execution_message do |target_issues|
          _('Marked this issue as related to %{issue_ref}.') % { issue_ref: target_issues.to_sentence }
        end
        params '<#issue | group/project#issue | issue URL>'
        types Issue
        condition { can_relate_issues? }
        parse_params { |issues| format_params(issues) }
        command :relate do |target_issues|
          create_links(target_issues)
        end

        private

        def create_links(references, type: 'relates_to')
          service = IssueLinks::CreateService.new(
            quick_action_target,
            current_user, { issuable_references: references, link_type: type }
          )
          create_issue_link = proc { service.execute }

          if quick_action_target.persisted?
            create_issue_link.call
          else
            quick_action_target.run_after_commit(&create_issue_link)
          end
        end

        def can_relate_issues?
          current_user.can?(:admin_issue_link, quick_action_target)
        end

        def format_params(issue_references)
          issue_references.split(' ')
        end
      end
    end
  end
end
