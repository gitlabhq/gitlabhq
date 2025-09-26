# frozen_string_literal: true

class AddIndexesToPartitionedProjectDailyStatistics < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  TABLE_NAME = :project_daily_statistics_b8088ecbd2
  INDEX_DEFINITIONS = [
    [
      [:project_id, :date],
      { name: 'idx_p_project_daily_statistics_on_project_id_and_date', unique: true, order: { date: :desc } }
    ],
    [[:date, :id], { name: 'idx_p_project_daily_statistics_on_date_and_id' }]
  ].freeze

  disable_ddl_transaction!
  milestone '18.5'

  def up
    INDEX_DEFINITIONS.each do |columns, options|
      add_concurrent_partitioned_index(TABLE_NAME, columns, options)
    end
  end

  def down
    INDEX_DEFINITIONS.each do |_columns, options| # rubocop:disable Style/HashEachMethods -- not a hash
      remove_concurrent_partitioned_index_by_name(TABLE_NAME, options[:name])
    end
  end
end
