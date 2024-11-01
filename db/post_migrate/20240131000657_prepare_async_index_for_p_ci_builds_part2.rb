# frozen_string_literal: true

class PrepareAsyncIndexForPCiBuildsPart2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'
  disable_ddl_transaction!

  INDEXES = [
    [[:upstream_pipeline_id_convert_to_bigint], "p_ci_builds_upstream_pipeline_id_bigint_idx",
      { where: 'upstream_pipeline_id_convert_to_bigint IS NOT NULL' }],
    [[:commit_id_convert_to_bigint, :type, :ref], "p_ci_builds_commit_id_bigint_type_ref_idx", {}],
    [[:commit_id_convert_to_bigint, :artifacts_expire_at, :id],
      "p_ci_builds_commit_id_bigint_artifacts_expire_at_id_idx", {
        where: "type::text = 'Ci::Build'::text AND (retried = false OR retried IS NULL) AND (name::text = ANY (ARRAY['sast'::character varying::text, 'secret_detection'::character varying::text, 'dependency_scanning'::character varying::text, 'container_scanning'::character varying::text, 'dast'::character varying::text]))"
      }]
  ]
  TABLE_NAME = :p_ci_builds

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |columns, routing_table_index_name, options|
        index_name = generated_index_name(partition.identifier, routing_table_index_name)
        prepare_async_index partition.identifier, columns, name: index_name, **options
      end
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |columns, routing_table_index_name, options|
        index_name = generated_index_name(partition.identifier, routing_table_index_name)
        unprepare_async_index partition.identifier, columns, name: index_name, **options
      end
    end
  end
end
