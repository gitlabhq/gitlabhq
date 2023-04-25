# frozen_string_literal: true

class AddCleanupAttemptsToLooseForeignKeysDeletedRecords < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :loose_foreign_keys_deleted_records, :cleanup_attempts, :smallint, default: 0
  end

  def down
    remove_column :loose_foreign_keys_deleted_records, :cleanup_attempts
  end
end
