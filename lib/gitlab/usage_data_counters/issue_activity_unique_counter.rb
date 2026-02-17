# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module IssueActivityUniqueCounter
      ISSUE_ASSIGNEE_CHANGED = 'g_project_management_issue_assignee_changed'
      ISSUE_CREATED = 'g_project_management_issue_created'
      ISSUE_DESCRIPTION_CHANGED = 'g_project_management_issue_description_changed'
      ISSUE_LABEL_CHANGED = 'g_project_management_issue_label_changed'
      ISSUE_MADE_CONFIDENTIAL = 'g_project_management_issue_made_confidential'
      ISSUE_MADE_VISIBLE = 'g_project_management_issue_made_visible'
      ISSUE_MILESTONE_CHANGED = 'g_project_management_issue_milestone_changed'
      ISSUE_TITLE_CHANGED = 'g_project_management_issue_title_changed'
      ISSUE_CROSS_REFERENCED = 'g_project_management_issue_cross_referenced'
      ISSUE_MARKED_AS_DUPLICATE = 'g_project_management_issue_marked_as_duplicate'
      ISSUE_LOCKED = 'g_project_management_issue_locked'
      ISSUE_UNLOCKED = 'g_project_management_issue_unlocked'
      ISSUE_DUE_DATE_CHANGED = 'g_project_management_issue_due_date_changed'
      ISSUE_TIME_ESTIMATE_CHANGED = 'g_project_management_issue_time_estimate_changed'
      ISSUE_TIME_SPENT_CHANGED = 'g_project_management_issue_time_spent_changed'
      ISSUE_COMMENT_ADDED = 'g_project_management_issue_comment_added'
      ISSUE_COMMENT_EDITED = 'g_project_management_issue_comment_edited'
      ISSUE_COMMENT_REMOVED = 'g_project_management_issue_comment_removed'
      ISSUE_DESIGN_COMMENT_REMOVED = 'g_project_management_issue_design_comments_removed'

      class << self
        def track_issue_created_action(author:, namespace:)
          track_internal_event(ISSUE_CREATED, author, namespace)
        end

        def track_issue_title_changed_action(author:, project:)
          track_internal_event(ISSUE_TITLE_CHANGED, author, project)
        end

        def track_issue_description_changed_action(author:, project:)
          track_internal_event(ISSUE_DESCRIPTION_CHANGED, author, project)
        end

        def track_issue_assignee_changed_action(author:, project:)
          track_internal_event(ISSUE_ASSIGNEE_CHANGED, author, project)
        end

        def track_issue_made_confidential_action(author:, project:)
          track_internal_event(ISSUE_MADE_CONFIDENTIAL, author, project)
        end

        def track_issue_made_visible_action(author:, project:)
          track_internal_event(ISSUE_MADE_VISIBLE, author, project)
        end

        def track_issue_label_changed_action(author:, project:)
          track_internal_event(ISSUE_LABEL_CHANGED, author, project)
        end

        def track_issue_milestone_changed_action(author:, project:)
          track_internal_event(ISSUE_MILESTONE_CHANGED, author, project)
        end

        def track_issue_cross_referenced_action(author:, project:)
          track_internal_event(ISSUE_CROSS_REFERENCED, author, project)
        end

        def track_issue_marked_as_duplicate_action(author:, project:)
          track_internal_event(ISSUE_MARKED_AS_DUPLICATE, author, project)
        end

        def track_issue_locked_action(author:, project:)
          track_internal_event(ISSUE_LOCKED, author, project)
        end

        def track_issue_unlocked_action(author:, project:)
          track_internal_event(ISSUE_UNLOCKED, author, project)
        end

        def track_issue_due_date_changed_action(author:, project:)
          track_internal_event(ISSUE_DUE_DATE_CHANGED, author, project)
        end

        def track_issue_time_estimate_changed_action(author:, project:)
          track_internal_event(ISSUE_TIME_ESTIMATE_CHANGED, author, project)
        end

        def track_issue_time_spent_changed_action(author:, project:)
          track_internal_event(ISSUE_TIME_SPENT_CHANGED, author, project)
        end

        def track_issue_comment_added_action(author:, project:)
          track_internal_event(ISSUE_COMMENT_ADDED, author, project)
        end

        def track_issue_comment_edited_action(author:, project:)
          track_internal_event(ISSUE_COMMENT_EDITED, author, project)
        end

        def track_issue_comment_removed_action(author:, project:)
          track_internal_event(ISSUE_COMMENT_REMOVED, author, project)
        end

        def track_issue_design_comment_removed_action(author:, project:)
          track_internal_event(ISSUE_DESIGN_COMMENT_REMOVED, author, project)
        end

        private

        def track_internal_event(event_name, author, container)
          return unless author

          namespace, project = get_params_from_container(container)

          Gitlab::InternalEvents.track_event(
            event_name,
            user: author,
            project: project,
            namespace: namespace
          )
        end

        def get_params_from_container(container)
          case container
          when Project
            [container.namespace, container]
          when Namespaces::ProjectNamespace
            [container.parent, container.project]
          else
            [container, nil]
          end
        end
      end
    end
  end
end

Gitlab::UsageDataCounters::IssueActivityUniqueCounter.prepend_mod_with('Gitlab::UsageDataCounters::IssueActivityUniqueCounter')
