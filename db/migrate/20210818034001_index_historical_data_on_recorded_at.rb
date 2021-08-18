# frozen_string_literal: true

class IndexHistoricalDataOnRecordedAt < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_historical_data_on_recorded_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :historical_data, :recorded_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :historical_data, INDEX_NAME
  end
end
