# frozen_string_literal: true

class CreateMergeRequestsMergeDataPartitionsForCells < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = :merge_requests_merge_data
  SOURCE_TABLE_NAME = 'merge_requests'
  PARTITION_SIZE = 10_000_000

  def up
    min_id = connection
      .select_value("SELECT min_value FROM pg_sequences WHERE sequencename = 'merge_requests_id_seq'") || 1

    # We just need to create partitions for Cells as we used fixed id(1) initially.
    return if min_id <= 1

    max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
        define_batchable_model('merge_requests', connection: connection).maximum(:id) || min_id
      end
    end

    create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, min_id, max_id)
  end

  def down
    # no op
  end
end
