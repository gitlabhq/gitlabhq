# frozen_string_literal: true

class FixPartitionIdsOnCiSourcesPipelines < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 50

  def up
    return unless Gitlab.com?

    model = define_batchable_model(:ci_sources_pipelines)

    batch_update_records(model, :partition_id, from: 101, to: 100, source_partition_id: 100)
    batch_update_records(model, :source_partition_id, from: 101, to: 100)
  end

  def down
    # no-op
  end

  private

  def batch_update_records(model, column, from:, to:, **updates)
    updates.reverse_merge!(column => to)

    model
      .where(model.arel_table[column].eq(from))
      .each_batch(of: BATCH_SIZE) { |batch| update_records(batch, updates) }
  end

  def update_records(relation, updates)
    relation.update_all(updates)
    sleep 0.1
  end
end
