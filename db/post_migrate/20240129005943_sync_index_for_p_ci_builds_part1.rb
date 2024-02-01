# frozen_string_literal: true

class SyncIndexForPCiBuildsPart1 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'

  TABLE_NAME = :p_ci_builds
  INDEXES = [
    ['p_ci_builds_auto_canceled_by_id_bigint_idx', [:auto_canceled_by_id_convert_to_bigint],
      { where: "auto_canceled_by_id_convert_to_bigint IS NOT NULL" }],
    ['p_ci_builds_commit_id_bigint_status_type_idx', [:commit_id_convert_to_bigint, :status, :type], {}],
    ['p_ci_builds_commit_id_bigint_type_name_ref_idx', [:commit_id_convert_to_bigint, :type, :name, :ref], {}]
  ]

  disable_ddl_transaction!

  def up
    INDEXES.each do |index_name, columns, options|
      add_concurrent_partitioned_index(TABLE_NAME, columns, name: index_name, **options)
    end
  end

  def down
    INDEXES.each do |index_name, _columns, _options|
      remove_concurrent_partitioned_index_by_name(TABLE_NAME, index_name)
    end
  end
end
