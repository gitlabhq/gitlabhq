# frozen_string_literal: true

class SyncIndexForPCiBuildsPart2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds
  INDEXES = [
    {
      name: "p_ci_builds_upstream_pipeline_id_bigint_idx",
      columns: [:upstream_pipeline_id_convert_to_bigint],
      options: { where: 'upstream_pipeline_id_convert_to_bigint IS NOT NULL' }
    },
    {
      name: "p_ci_builds_commit_id_bigint_type_ref_idx",
      columns: [:commit_id_convert_to_bigint, :type, :ref]
    },
    {
      name: "p_ci_builds_commit_id_bigint_artifacts_expire_at_id_idx",
      columns: [:commit_id_convert_to_bigint, :artifacts_expire_at, :id],
      options: {
        where: "type::text = 'Ci::Build'::text AND (retried = false OR retried IS NULL) AND (name::text = ANY (ARRAY['sast'::character varying::text, 'secret_detection'::character varying::text, 'dependency_scanning'::character varying::text, 'container_scanning'::character varying::text, 'dast'::character varying::text]))"
      }
    }
  ]

  def up
    INDEXES.each do |definition|
      name, columns, options = definition.values_at(:name, :columns, :options)
      add_concurrent_partitioned_index(TABLE_NAME, columns, name: name, **(options || {}))
    end
  end

  def down
    INDEXES.each do |definition|
      name = definition[:name]
      remove_concurrent_partitioned_index_by_name(TABLE_NAME, name)
    end
  end
end
