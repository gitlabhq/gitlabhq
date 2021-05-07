# frozen_string_literal: true

module SystemNotes
  class TimeTrackingService < ::SystemNotes::BaseService
    # Called when the due_date of a Noteable is changed
    #
    # due_date  - Due date being assigned, or nil
    #
    # Example Note text:
    #
    #   "removed due date"
    #
    #   "changed due date to September 20, 2018"
    #
    # Returns the created Note object
    def change_due_date(due_date)
      body = due_date ? "changed due date to #{due_date.to_s(:long)}" : 'removed due date'

      issue_activity_counter.track_issue_due_date_changed_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'due_date'))
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
      parsed_time = Gitlab::TimeTrackingFormatter.output(noteable.time_estimate)
      body = if noteable.time_estimate == 0
               "removed time estimate"
             else
               "changed time estimate to #{parsed_time}"
             end

      issue_activity_counter.track_issue_time_estimate_changed_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'time_tracking'))
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

      issue_activity_counter.track_issue_time_spent_changed_action(author: author) if noteable.is_a?(Issue)

      create_note(NoteSummary.new(noteable, project, author, body, action: 'time_tracking'))
    end

    private

    def issue_activity_counter
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter
    end
  end
end
