# frozen_string_literal: true

class AddIndexOnOkrReminderFrequency < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'idx_reminder_frequency_on_work_item_progresses'

  disable_ddl_transaction!

  def up
    add_concurrent_index :work_item_progresses, :reminder_frequency, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :work_item_progresses, INDEX_NAME
  end
end
