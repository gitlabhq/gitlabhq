# frozen_string_literal: true

module SystemNotes
  class TimeTrackingService < ::SystemNotes::BaseService
    # Called when the start_date or due_date of an Issue/WorkItem is changed
    #
    # start_date  - Start date being assigned, or nil
    # due_date  - Due date being assigned, or nil
    #
    # Example Note text:
    #
    #   "removed due date"
    #
    #   "changed due date to September 20, 2018"

    #   "changed start date to September 20, 2018 and changed due date to September 25, 2018"
    #
    # Returns the created Note object
    def change_start_date_or_due_date(changed_dates = {})
      return if changed_dates.empty?

      # Using instance_of because WorkItem < Issue. We don't want to track work item updates as issue updates
      if noteable.instance_of?(Issue) && changed_dates.key?('due_date')
        issue_activity_counter.track_issue_due_date_changed_action(author: author, project: project)
      end

      work_item_activity_counter.track_work_item_date_changed_action(author: author) if noteable.is_a?(WorkItem)

      create_note(
        NoteSummary.new(noteable, project, author, changed_date_body(changed_dates), action: 'start_date_or_due_date')
      )
    end

    # Called when the estimated time of a Noteable is changed
    #
    # time_estimate - Estimated time
    #
    # Example Note text:
    #
    #   "removed time estimate"
    #
    #   "changed time estimate to 3d 5h"
    #
    # Returns the created Note object
    def change_time_estimate
      if noteable.is_a?(Issue)
        issue_activity_counter.track_issue_time_estimate_changed_action(author: author, project: project)
      end

      create_note(NoteSummary.new(noteable, project, author, time_estimate_system_note, action: 'time_tracking'))
    end

    # Called when the spent time of a Noteable is changed
    #
    # time_spent - Spent time
    #
    # Example Note text:
    #
    #   "removed time spent"
    #
    #   "added 2h 30m of time spent"
    #
    # Returns the created Note object
    def change_time_spent
      time_spent = noteable.time_spent

      if time_spent == :reset
        body = "removed time spent"
      else
        spent_at = noteable.spent_at&.to_date
        parsed_time = Gitlab::TimeTrackingFormatter.output(time_spent.abs)
        action = time_spent > 0 ? 'added' : 'subtracted'

        text_parts = ["#{action} #{parsed_time} of time spent"]
        text_parts << "at #{spent_at}" if spent_at && spent_at != DateTime.current.to_date
        body = text_parts.join(' ')
      end

      if noteable.is_a?(Issue)
        issue_activity_counter.track_issue_time_spent_changed_action(author: author, project: project)
      end

      create_note(NoteSummary.new(noteable, project, author, body, action: 'time_tracking'))
    end

    # Called when a timelog is added to an issuable
    #
    # timelog - Added timelog
    #
    # Example Note text:
    #
    #   "subtracted 1h 15m of time spent"
    #
    #   "added 2h 30m of time spent"
    #
    # Returns the created Note object
    def created_timelog(timelog)
      time_spent = timelog.time_spent
      spent_at = timelog.spent_at&.to_date
      parsed_time = Gitlab::TimeTrackingFormatter.output(time_spent.abs)
      action = time_spent > 0 ? 'added' : 'subtracted'

      text_parts = ["#{action} #{parsed_time} of time spent"]
      text_parts << "at #{spent_at}" if spent_at && spent_at != DateTime.current.to_date
      body = text_parts.join(' ')

      if noteable.is_a?(Issue)
        issue_activity_counter.track_issue_time_spent_changed_action(author: author, project: project)
      end

      create_note(NoteSummary.new(noteable, project, author, body, action: 'time_tracking'))
    end

    def remove_timelog(timelog)
      time_spent = timelog.time_spent
      spent_at = timelog.spent_at&.to_date

      parsed_time = Gitlab::TimeTrackingFormatter.output(time_spent)

      body = "deleted #{parsed_time} of spent time"
      body += " from #{spent_at}" if spent_at

      create_note(NoteSummary.new(noteable, project, author, body, action: 'time_tracking'))
    end

    private

    def changed_date_body(changed_dates)
      %w[start_date due_date].each_with_object([]) do |date_field, word_array|
        next unless changed_dates.key?(date_field)

        word_array << 'and' if word_array.any?

        word_array << message_for_changed_date(changed_dates, date_field)
      end.join(' ')
    end

    def message_for_changed_date(changed_dates, date_key)
      changed_date = changed_dates[date_key].last
      readable_date = date_key.humanize.downcase

      if changed_date.nil?
        "removed #{readable_date} #{changed_dates[date_key].first.to_fs(:long)}"
      else
        "changed #{readable_date} to #{changed_date.to_fs(:long)}"
      end
    end

    def issue_activity_counter
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter
    end

    def work_item_activity_counter
      Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter
    end

    def time_estimate_system_note
      parsed_time = Gitlab::TimeTrackingFormatter.output(noteable.time_estimate)
      previous_estimate = noteable.previous_changes['time_estimate']&.at(0) || 0
      parsed_previous_restimate = Gitlab::TimeTrackingFormatter.output(previous_estimate)

      if previous_estimate == 0
        "added time estimate of #{parsed_time}"
      elsif noteable.time_estimate == 0
        "removed time estimate of #{parsed_previous_restimate}"
      else
        "changed time estimate to #{parsed_time} from #{parsed_previous_restimate}"
      end
    end
  end
end
