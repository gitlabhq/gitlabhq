# frozen_string_literal: true

class RemoveRawUsageDataRecordedAtIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  INDEX_NAME = 'index_raw_usage_data_on_recorded_at'

  def up
    remove_concurrent_index :raw_usage_data, :recorded_at, name: INDEX_NAME
  end

  def down
    add_concurrent_index :raw_usage_data, :recorded_at, name: INDEX_NAME, unique: true
  end
end
