# frozen_string_literal: true

class AddNotesToTimelogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :timelogs, :note_id, :integer
    end
    add_concurrent_index :timelogs, :note_id
    add_concurrent_foreign_key :timelogs, :notes, column: :note_id
  end

  def down
    remove_foreign_key_if_exists :timelogs, column: :note_id
    remove_concurrent_index :timelogs, :note_id
    with_lock_retries do
      remove_column :timelogs, :note_id
    end
  end
end
