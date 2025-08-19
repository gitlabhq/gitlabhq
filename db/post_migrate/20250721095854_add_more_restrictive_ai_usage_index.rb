# frozen_string_literal: true

class AddMoreRestrictiveAiUsageIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  # Here we add index to an empty partitioned table which needs to lock all partitions.
  skip_require_disable_ddl_transactions!

  milestone '18.3'

  OLD_INDEX_NAME = 'idx_ai_usage_events_unique_tuple'
  NAMESPACE_INDEX_NAME = 'idx_ai_usage_events_namespace_id'
  INDEX_NAME = 'idx_ai_usage_events_uniqueness'
  COLUMN_NAMES = %i[namespace_id user_id event timestamp].freeze # rubocop: disable Migration/Datetime -- timestamp is a column

  # rubocop: disable Migration/AddIndex -- table is empty
  # rubocop: disable Migration/RemoveIndex -- table is empty
  # rubocop: disable Migration/ComplexIndexesRequireName -- index name is part of the index options hash
  def up
    truncate_tables!('ai_usage_events')
    partitioned_table = find_partitioned_table('ai_usage_events')

    index_options = {
      name: INDEX_NAME,
      unique: true,
      nulls_not_distinct: true
    }

    partitioned_table.postgres_partitions.order(:name).each do |partition|
      partition_index_name = generated_index_name(partition.identifier, index_options[:name])
      partition_options = index_options.merge(name: partition_index_name)

      add_index partition.identifier, COLUMN_NAMES, **partition_options
    end

    add_index :ai_usage_events, COLUMN_NAMES, **index_options

    remove_index :ai_usage_events, name: OLD_INDEX_NAME
  end

  def down
    # Adding the old index is possible because its configuration is less restrictive than the new index.
    partitioned_table = find_partitioned_table('ai_usage_events')

    index_options = {
      name: OLD_INDEX_NAME,
      unique: true
    }

    partitioned_table.postgres_partitions.order(:name).each do |partition|
      partition_index_name = generated_index_name(partition.identifier, index_options[:name])
      partition_options = index_options.merge(name: partition_index_name)

      add_index partition.identifier, COLUMN_NAMES, **partition_options
    end

    add_index :ai_usage_events, COLUMN_NAMES, **index_options

    remove_index :ai_usage_events, name: INDEX_NAME
  end
  # rubocop: enable Migration/AddIndex
  # rubocop: enable Migration/RemoveIndex
  # rubocop: enable Migration/ComplexIndexesRequireName
end
