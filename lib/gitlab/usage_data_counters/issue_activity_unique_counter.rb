# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module IssueActivityUniqueCounter
      ISSUE_TITLE_CHANGED = 'g_project_management_issue_title_changed'
      ISSUE_DESCRIPTION_CHANGED = 'g_project_management_issue_description_changed'
      ISSUE_ASSIGNEE_CHANGED = 'g_project_management_issue_assignee_changed'
      ISSUE_MADE_CONFIDENTIAL = 'g_project_management_issue_made_confidential'
      ISSUE_MADE_VISIBLE = 'g_project_management_issue_made_visible'
      ISSUE_CATEGORY = 'issues_edit'

      class << self
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
