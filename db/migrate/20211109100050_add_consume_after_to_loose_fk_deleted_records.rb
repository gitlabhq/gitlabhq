# frozen_string_literal: true

class AddConsumeAfterToLooseFkDeletedRecords < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :loose_foreign_keys_deleted_records, :consume_after, :datetime_with_timezone, default: -> { 'NOW()' }
  end

  def down
    remove_column :loose_foreign_keys_deleted_records, :consume_after
  end
end
