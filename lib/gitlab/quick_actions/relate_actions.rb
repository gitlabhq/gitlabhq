# frozen_string_literal: true

module Gitlab
  module QuickActions
    module RelateActions
      extend ActiveSupport::Concern
      include ::Gitlab::QuickActions::Dsl

      included do
        desc { _('Link items related to this item') }
        explanation do |target_issues|
          format(
            _('Added %{target} as a linked item related to this %{work_item_type}.'),
            target: target_issues.to_sentence,
            work_item_type: work_item_type(quick_action_target)
          )
        end
        execution_message do |target_issues|
          format(
            _('Added %{target} as a linked item related to this %{work_item_type}.'),
            target: target_issues.to_sentence,
            work_item_type: work_item_type(quick_action_target)
          )
        end
        params '<#item | group/project#item | item URL>'
        types Issue
        condition { can_admin_link? }
        parse_params { |issues| format_params(issues) }
        command :relate do |target_issues|
          create_links(target_issues)
        end

        desc { _("Remove linked item") }
        explanation do |issue|
          _('Removes linked item %{issue_ref}.') % { issue_ref: issue.to_reference(quick_action_target) }
        end
        execution_message do |issue|
          _('Removed linked item %{issue_ref}.') % { issue_ref: issue.to_reference(quick_action_target) }
        end
        params '<#item | group/project#item | item URL>'
        types Issue
        condition { can_admin_link? }
        parse_params do |issue_param|
          items = extract_references(issue_param, :issue) + extract_references(issue_param, :work_item)
          items.first
        end
        command :unlink do |issue|
          link = IssueLink.for_items(quick_action_target, issue).first

          if link
            user = current_user

            call_link_service(proc { IssueLinks::DestroyService.new(link, user).execute })
          else
            @execution_message[:unlink] = _('No linked issue matches the provided parameter.')
          end
        end

        private

        def can_admin_link?
          current_user.can?(:admin_issue_link, quick_action_target)
        end

        def create_links(references, type: 'relates_to')
          target = quick_action_target
          user = current_user

          link_service = proc do
            ::WorkItems::RelatedWorkItemLinks::CreateService.new(
              WorkItem.find(target.id),
              user, { issuable_references: references, link_type: type }
            ).execute
          end

          call_link_service(link_service)
        end

        def call_link_service(link_service)
          if quick_action_target.persisted?
            link_service.call
          else
            quick_action_target.run_after_commit(&link_service)
          end
        end

        def format_params(issue_references)
          issue_references.split(' ')
        end

        def work_item_type(work_item)
          work_item.work_item_type.name.downcase
        end
      end
    end
  end
end
