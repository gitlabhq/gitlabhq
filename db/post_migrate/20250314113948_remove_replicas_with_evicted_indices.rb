# frozen_string_literal: true

class RemoveReplicasWithEvictedIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.10'
  BATCH_SIZE = 500
  EVICTED_STATE = 225
  SCOPE_SQL = ['state = ? AND zoekt_replica_id IS NOT NULL', EVICTED_STATE]

  def up
    each_batch_range('zoekt_indices', scope: ->(table) { table.where(SCOPE_SQL) }, of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM zoekt_replicas
          USING zoekt_indices
          WHERE zoekt_indices.zoekt_replica_id = zoekt_replicas.id
            AND zoekt_indices.id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # no-op
  end
end
