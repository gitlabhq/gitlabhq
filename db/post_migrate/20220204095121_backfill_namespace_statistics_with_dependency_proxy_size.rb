# frozen_string_literal: true

class BackfillNamespaceStatisticsWithDependencyProxySize < Gitlab::Database::Migration[1.0]
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION = 'PopulateNamespaceStatistics'

  disable_ddl_transaction!

  def up
    groups = exec_query <<~SQL
      SELECT dependency_proxy_manifests.group_id FROM dependency_proxy_manifests
      UNION
      SELECT dependency_proxy_blobs.group_id from dependency_proxy_blobs
    SQL

    groups.rows.flatten.in_groups_of(BATCH_SIZE, false).each_with_index do |group_ids, index|
      migrate_in(index * DELAY_INTERVAL, MIGRATION, [group_ids, [:dependency_proxy_size]])
    end
  end

  def down
    # no-op
  end
end
