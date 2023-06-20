# frozen_string_literal: true

class MigrateDailyRedisHllEventsToWeeklyAggregation < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  DAILY_EVENTS =
    %w[g_edit_by_web_ide
      g_edit_by_sfe
      g_edit_by_snippet_ide
      g_edit_by_live_preview
      wiki_action
      design_action
      project_action
      git_write_action
      merge_request_action
      i_source_code_code_intelligence
      g_project_management_issue_title_changed
      g_project_management_issue_description_changed
      g_project_management_issue_assignee_changed
      g_project_management_issue_made_confidential
      g_project_management_issue_made_visible
      g_project_management_issue_created
      g_project_management_issue_closed
      g_project_management_issue_reopened
      g_project_management_issue_label_changed
      g_project_management_issue_milestone_changed
      g_project_management_issue_cross_referenced
      g_project_management_issue_moved
      g_project_management_issue_related
      g_project_management_issue_unrelated
      g_project_management_issue_marked_as_duplicate
      g_project_management_issue_locked
      g_project_management_issue_unlocked
      g_project_management_issue_designs_added
      g_project_management_issue_designs_modified
      g_project_management_issue_designs_removed
      g_project_management_issue_due_date_changed
      g_project_management_issue_design_comments_removed
      g_project_management_issue_time_estimate_changed
      g_project_management_issue_time_spent_changed
      g_project_management_issue_comment_added
      g_project_management_issue_comment_edited
      g_project_management_issue_comment_removed
      g_project_management_issue_cloned
      g_geo_proxied_requests
      approval_project_rule_created
      g_project_management_issue_added_to_epic
      g_project_management_issue_changed_epic
      g_project_management_issue_health_status_changed
      g_project_management_issue_iteration_changed
      g_project_management_issue_removed_from_epic
      g_project_management_issue_weight_changed
      g_geo_proxied_requests
      g_project_management_users_creating_epic_boards
      g_project_management_users_viewing_epic_boards
      g_project_management_users_updating_epic_board_names
      g_project_management_epic_created
      project_management_users_unchecking_epic_task
      project_management_users_checking_epic_task
      g_project_management_users_updating_epic_titles
      g_project_management_users_updating_epic_descriptions
      g_project_management_users_creating_epic_notes
      g_project_management_users_updating_epic_notes
      g_project_management_users_destroying_epic_notes
      g_project_management_users_awarding_epic_emoji
      g_project_management_users_removing_epic_emoji
      g_project_management_users_setting_epic_start_date_as_fixed
      g_project_management_users_updating_fixed_epic_start_date
      g_project_management_users_setting_epic_start_date_as_inherited
      g_project_management_users_setting_epic_due_date_as_fixed
      g_project_management_users_updating_fixed_epic_due_date
      g_project_management_users_setting_epic_due_date_as_inherited
      g_project_management_epic_issue_added
      g_project_management_epic_issue_removed
      g_project_management_epic_issue_moved_from_project
      g_project_management_users_updating_epic_parent
      g_project_management_epic_closed
      g_project_management_epic_reopened
      g_project_management_issue_promoted_to_epic
      g_project_management_users_setting_epic_confidential
      g_project_management_users_setting_epic_visible
      g_project_management_epic_users_changing_labels
      g_project_management_epic_destroyed
      g_project_management_epic_cross_referenced
      g_project_management_users_epic_issue_added_from_epic
      g_project_management_epic_related_added
      g_project_management_epic_related_removed
      g_project_management_epic_blocking_added
      g_project_management_epic_blocking_removed
      g_project_management_epic_blocked_added
      g_project_management_epic_blocked_removed].freeze

  def up
    days_back = 29.days
    start_date = Date.today - days_back - 1.day
    end_date = Date.today + 1.day
    keys = {}

    Gitlab::UsageDataCounters::HLLRedisCounter.known_events.each do |event|
      next unless DAILY_EVENTS.include?(event[:name].to_s)

      (start_date..end_date).each do |date|
        daily_key = redis_key(event, date, :daily)
        weekly_key = redis_key(event, date, :weekly)

        keys.key?(weekly_key) ? keys[weekly_key] << daily_key : keys[weekly_key] = [daily_key]
      end
    end

    keys.each do |weekly_key, daily_keys|
      Gitlab::Redis::SharedState.with do |redis|
        redis.pfmerge(weekly_key, *daily_keys)
        redis.expire(weekly_key, 6.weeks)
      end
    end
  end

  def down
    # no-op
  end

  # can't set daily key in HLLRedisCounter anymore, so need to duplicate logic here
  def redis_key(event, time, aggregation)
    key = "{hll_counters}_#{event[:name]}"
    if aggregation.to_sym == :daily
      year_day = time.strftime('%G-%j')
      "#{year_day}-#{key}"
    else
      year_week = time.strftime('%G-%V')
      "#{key}-#{year_week}"
    end
  end
end
