# frozen_string_literal: true

# Expected migration duration: 1 minute
class FillProductivityAnalyticsStartDate < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_request_metrics, :merged_at,
                         where: "merged_at > '2019-09-01' AND commits_count IS NOT NULL",
                         name: 'fill_productivity_analytics_start_date_tmp_index'

    execute(
      <<SQL
        UPDATE application_settings
        SET productivity_analytics_start_date = COALESCE((SELECT MIN(merged_at) FROM merge_request_metrics
            WHERE merged_at > '2019-09-01' AND commits_count IS NOT NULL), NOW())
SQL
    )

    remove_concurrent_index :merge_request_metrics, :merged_at,
                            name: 'fill_productivity_analytics_start_date_tmp_index'
  end

  def down
    execute('UPDATE application_settings SET productivity_analytics_start_date = NULL')
  end
end
