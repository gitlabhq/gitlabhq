# frozen_string_literal: true

class AddOkrReminderFieldsToWorkItemProgresses < Gitlab::Database::Migration[2.1]
  def change
    add_column :work_item_progresses, :reminder_frequency, :integer, limit: 2, null: false, default: 0
  end
end
