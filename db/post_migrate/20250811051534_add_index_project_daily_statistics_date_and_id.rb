# frozen_string_literal: true

class AddIndexProjectDailyStatisticsDateAndId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  INDEX_NAME = 'index_project_daily_statistics_on_date_and_id'

  def up
    add_concurrent_index :project_daily_statistics, [:date, :id], name: INDEX_NAME, if_not_exists: true
  end

  def down
    remove_concurrent_index_by_name :project_daily_statistics, INDEX_NAME
  end
end
