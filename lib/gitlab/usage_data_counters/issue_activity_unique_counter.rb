# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module IssueActivityUniqueCounter
      ISSUE_CATEGORY = 'issues_edit'

      ISSUE_ASSIGNEE_CHANGED = 'g_project_management_issue_assignee_changed'
      ISSUE_CREATED = 'g_project_management_issue_created'
      ISSUE_CLOSED = 'g_project_management_issue_closed'
      ISSUE_DESCRIPTION_CHANGED = 'g_project_management_issue_description_changed'
      ISSUE_ITERATION_CHANGED = 'g_project_management_issue_iteration_changed'
      ISSUE_LABEL_CHANGED = 'g_project_management_issue_label_changed'
      ISSUE_MADE_CONFIDENTIAL = 'g_project_management_issue_made_confidential'
      ISSUE_MADE_VISIBLE = 'g_project_management_issue_made_visible'
      ISSUE_MILESTONE_CHANGED = 'g_project_management_issue_milestone_changed'
      ISSUE_REOPENED = 'g_project_management_issue_reopened'
      ISSUE_TITLE_CHANGED = 'g_project_management_issue_title_changed'
      ISSUE_WEIGHT_CHANGED = 'g_project_management_issue_weight_changed'

      class << self
        def track_issue_created_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_CREATED, author, time)
        end

        def track_issue_title_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_TITLE_CHANGED, author, time)
        end

        def track_issue_description_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_DESCRIPTION_CHANGED, author, time)
        end

        def track_issue_assignee_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_ASSIGNEE_CHANGED, author, time)
        end

        def track_issue_made_confidential_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MADE_CONFIDENTIAL, author, time)
        end

        def track_issue_made_visible_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MADE_VISIBLE, author, time)
        end

        def track_issue_closed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_CLOSED, author, time)
        end

        def track_issue_reopened_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_REOPENED, author, time)
        end

        def track_issue_label_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_LABEL_CHANGED, author, time)
        end

        def track_issue_milestone_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MILESTONE_CHANGED, author, time)
        end

        def track_issue_iteration_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_ITERATION_CHANGED, author, time)
        end

        def track_issue_weight_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_WEIGHT_CHANGED, author, time)
        end

        private

        def track_unique_action(action, author, time)
          return unless Feature.enabled?(:track_issue_activity_actions)
          return unless author

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(author.id, action, time)
        end
      end
    end
  end
end
