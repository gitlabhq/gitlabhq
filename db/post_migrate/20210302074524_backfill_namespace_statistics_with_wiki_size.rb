# frozen_string_literal: true

class BackfillNamespaceStatisticsWithWikiSize < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION = 'PopulateNamespaceStatistics'

  disable_ddl_transaction!

  def up
    return unless Gitlab.ee?

    groups = exec_query <<~SQL
      SELECT group_wiki_repositories.group_id
      FROM group_wiki_repositories
    SQL

    groups.rows.flatten.in_groups_of(BATCH_SIZE, false).each_with_index do |group_ids, index|
      migrate_in(index * DELAY_INTERVAL, MIGRATION, [group_ids, [:wiki_size]])
    end
  end

  def down
    # No-op
  end
end
