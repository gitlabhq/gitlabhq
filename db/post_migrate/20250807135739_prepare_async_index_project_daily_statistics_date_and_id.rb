# frozen_string_literal: true

class PrepareAsyncIndexProjectDailyStatisticsDateAndId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'index_project_daily_statistics_on_date_and_id'
  TABLE_NAME = :project_daily_statistics

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/560318
  def up
    prepare_async_index :project_daily_statistics, [:date, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index :project_daily_statistics, [:date, :id], name: INDEX_NAME
  end
end
