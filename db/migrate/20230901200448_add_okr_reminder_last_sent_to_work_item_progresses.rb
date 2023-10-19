# frozen_string_literal: true

class AddOkrReminderLastSentToWorkItemProgresses < Gitlab::Database::Migration[2.1]
  def change
    add_column :work_item_progresses, :last_reminder_sent_at, :datetime_with_timezone
  end
end
