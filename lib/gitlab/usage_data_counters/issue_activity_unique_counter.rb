# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module IssueActivityUniqueCounter
      ISSUE_CATEGORY = 'issues_edit'
      ISSUE_ACTION = 'perform_issue_action'
      ISSUE_LABEL = 'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_monthly'

      ISSUE_ASSIGNEE_CHANGED = 'g_project_management_issue_assignee_changed'
      ISSUE_CREATED = 'g_project_management_issue_created'
      ISSUE_CLOSED = 'g_project_management_issue_closed'
      ISSUE_DESCRIPTION_CHANGED = 'g_project_management_issue_description_changed'
      ISSUE_LABEL_CHANGED = 'g_project_management_issue_label_changed'
      ISSUE_MADE_CONFIDENTIAL = 'g_project_management_issue_made_confidential'
      ISSUE_MADE_VISIBLE = 'g_project_management_issue_made_visible'
      ISSUE_MILESTONE_CHANGED = 'g_project_management_issue_milestone_changed'
      ISSUE_REOPENED = 'g_project_management_issue_reopened'
      ISSUE_TITLE_CHANGED = 'g_project_management_issue_title_changed'
      ISSUE_CROSS_REFERENCED = 'g_project_management_issue_cross_referenced'
      ISSUE_MOVED = 'g_project_management_issue_moved'
      ISSUE_RELATED = 'g_project_management_issue_related'
      ISSUE_CLONED = 'g_project_management_issue_cloned'
      ISSUE_UNRELATED = 'g_project_management_issue_unrelated'
      ISSUE_MARKED_AS_DUPLICATE = 'g_project_management_issue_marked_as_duplicate'
      ISSUE_LOCKED = 'g_project_management_issue_locked'
      ISSUE_UNLOCKED = 'g_project_management_issue_unlocked'
      ISSUE_DESIGNS_ADDED = 'g_project_management_issue_designs_added'
      ISSUE_DESIGNS_MODIFIED = 'g_project_management_issue_designs_modified'
      ISSUE_DESIGNS_REMOVED = 'g_project_management_issue_designs_removed'
      ISSUE_DUE_DATE_CHANGED = 'g_project_management_issue_due_date_changed'
      ISSUE_TIME_ESTIMATE_CHANGED = 'g_project_management_issue_time_estimate_changed'
      ISSUE_TIME_SPENT_CHANGED = 'g_project_management_issue_time_spent_changed'
      ISSUE_COMMENT_ADDED = 'g_project_management_issue_comment_added'
      ISSUE_COMMENT_EDITED = 'g_project_management_issue_comment_edited'
      ISSUE_COMMENT_REMOVED = 'g_project_management_issue_comment_removed'
      ISSUE_DESIGN_COMMENT_REMOVED = 'g_project_management_issue_design_comments_removed'

      class << self
        def track_issue_created_action(author:, namespace:)
          track_snowplow_action(ISSUE_CREATED, author, namespace)
          track_unique_action(ISSUE_CREATED, author)
        end

        def track_issue_title_changed_action(author:, project:)
          track_snowplow_action(ISSUE_TITLE_CHANGED, author, project)
          track_unique_action(ISSUE_TITLE_CHANGED, author)
        end

        def track_issue_description_changed_action(author:, project:)
          track_snowplow_action(ISSUE_DESCRIPTION_CHANGED, author, project)
          track_unique_action(ISSUE_DESCRIPTION_CHANGED, author)
        end

        def track_issue_assignee_changed_action(author:, project:)
          track_snowplow_action(ISSUE_ASSIGNEE_CHANGED, author, project)
          track_unique_action(ISSUE_ASSIGNEE_CHANGED, author)
        end

        def track_issue_made_confidential_action(author:, project:)
          track_snowplow_action(ISSUE_MADE_CONFIDENTIAL, author, project)
          track_unique_action(ISSUE_MADE_CONFIDENTIAL, author)
        end

        def track_issue_made_visible_action(author:, project:)
          track_snowplow_action(ISSUE_MADE_VISIBLE, author, project)
          track_unique_action(ISSUE_MADE_VISIBLE, author)
        end

        def track_issue_closed_action(author:, project:)
          track_snowplow_action(ISSUE_CLOSED, author, project)
          track_unique_action(ISSUE_CLOSED, author)
        end

        def track_issue_reopened_action(author:, project:)
          track_snowplow_action(ISSUE_REOPENED, author, project)
          track_unique_action(ISSUE_REOPENED, author)
        end

        def track_issue_label_changed_action(author:, project:)
          track_snowplow_action(ISSUE_LABEL_CHANGED, author, project)
          track_unique_action(ISSUE_LABEL_CHANGED, author)
        end

        def track_issue_milestone_changed_action(author:, project:)
          track_snowplow_action(ISSUE_MILESTONE_CHANGED, author, project)
          track_unique_action(ISSUE_MILESTONE_CHANGED, author)
        end

        def track_issue_cross_referenced_action(author:, project:)
          track_snowplow_action(ISSUE_CROSS_REFERENCED, author, project)
          track_unique_action(ISSUE_CROSS_REFERENCED, author)
        end

        def track_issue_moved_action(author:, project:)
          track_snowplow_action(ISSUE_MOVED, author, project)
          track_unique_action(ISSUE_MOVED, author)
        end

        def track_issue_related_action(author:, project:)
          track_snowplow_action(ISSUE_RELATED, author, project)
          track_unique_action(ISSUE_RELATED, author)
        end

        def track_issue_unrelated_action(author:, project:)
          track_snowplow_action(ISSUE_UNRELATED, author, project)
          track_unique_action(ISSUE_UNRELATED, author)
        end

        def track_issue_marked_as_duplicate_action(author:, project:)
          track_snowplow_action(ISSUE_MARKED_AS_DUPLICATE, author, project)
          track_unique_action(ISSUE_MARKED_AS_DUPLICATE, author)
        end

        def track_issue_locked_action(author:, project:)
          track_snowplow_action(ISSUE_LOCKED, author, project)
          track_unique_action(ISSUE_LOCKED, author)
        end

        def track_issue_unlocked_action(author:, project:)
          track_snowplow_action(ISSUE_UNLOCKED, author, project)
          track_unique_action(ISSUE_UNLOCKED, author)
        end

        def track_issue_designs_added_action(author:, project:)
          track_snowplow_action(ISSUE_DESIGNS_ADDED, author, project)
          track_unique_action(ISSUE_DESIGNS_ADDED, author)
        end

        def track_issue_designs_modified_action(author:, project:)
          track_snowplow_action(ISSUE_DESIGNS_MODIFIED, author, project)
          track_unique_action(ISSUE_DESIGNS_MODIFIED, author)
        end

        def track_issue_designs_removed_action(author:, project:)
          track_snowplow_action(ISSUE_DESIGNS_REMOVED, author, project)
          track_unique_action(ISSUE_DESIGNS_REMOVED, author)
        end

        def track_issue_due_date_changed_action(author:, project:)
          track_snowplow_action(ISSUE_DUE_DATE_CHANGED, author, project)
          track_unique_action(ISSUE_DUE_DATE_CHANGED, author)
        end

        def track_issue_time_estimate_changed_action(author:, project:)
          track_snowplow_action(ISSUE_TIME_ESTIMATE_CHANGED, author, project)
          track_unique_action(ISSUE_TIME_ESTIMATE_CHANGED, author)
        end

        def track_issue_time_spent_changed_action(author:, project:)
          track_snowplow_action(ISSUE_TIME_SPENT_CHANGED, author, project)
          track_unique_action(ISSUE_TIME_SPENT_CHANGED, author)
        end

        def track_issue_comment_added_action(author:, project:)
          track_snowplow_action(ISSUE_COMMENT_ADDED, author, project)
          track_unique_action(ISSUE_COMMENT_ADDED, author)
        end

        def track_issue_comment_edited_action(author:, project:)
          track_snowplow_action(ISSUE_COMMENT_EDITED, author, project)
          track_unique_action(ISSUE_COMMENT_EDITED, author)
        end

        def track_issue_comment_removed_action(author:, project:)
          track_snowplow_action(ISSUE_COMMENT_REMOVED, author, project)
          track_unique_action(ISSUE_COMMENT_REMOVED, author)
        end

        def track_issue_cloned_action(author:, project:)
          track_snowplow_action(ISSUE_CLONED, author, project)
          track_unique_action(ISSUE_CLONED, author)
        end

        def track_issue_design_comment_removed_action(author:, project:)
          track_snowplow_action(ISSUE_DESIGN_COMMENT_REMOVED, author, project)
          track_unique_action(ISSUE_DESIGN_COMMENT_REMOVED, author)
        end

        private

        def track_snowplow_action(event_name, author, container)
          namespace, project = case container
                               when Project
                                 [container.namespace, container]
                               when Namespaces::ProjectNamespace
                                 [container.parent, container.project]
                               else
                                 [container, nil]
                               end

          return unless author

          Gitlab::Tracking.event(
            ISSUE_CATEGORY,
            ISSUE_ACTION,
            label: ISSUE_LABEL,
            property: event_name,
            project: project,
            namespace: namespace,
            user: author,
            context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event_name).to_context]
          )
        end

        def track_unique_action(event_name, author)
          return unless author

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: author.id)
        end
      end
    end
  end
end

Gitlab::UsageDataCounters::IssueActivityUniqueCounter.prepend_mod_with('Gitlab::UsageDataCounters::IssueActivityUniqueCounter')
