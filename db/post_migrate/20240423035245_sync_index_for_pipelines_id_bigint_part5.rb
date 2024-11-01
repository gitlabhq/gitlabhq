# frozen_string_literal: true

class SyncIndexForPipelinesIdBigintPart5 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'
  disable_ddl_transaction!

  INDEXES = [
    {
      name: :p_ci_builds_project_id_bigint_name_ref_idx,
      columns: [:project_id_convert_to_bigint, :name, :ref],
      options: { where: "type::text = 'Ci::Build'::text AND status::text = 'success'::text AND (retried = false OR retried IS NULL)" }
    },
    {
      name: :p_ci_builds_project_id_bigint_status_idx,
      columns: [:project_id_convert_to_bigint, :status],
      options: { where: "type::text = 'Ci::Build'::text AND (status::text = ANY (ARRAY['running'::character varying::text, 'pending'::character varying::text, 'created'::character varying::text]))" }
    },
    {
      name: :p_ci_builds_status_created_at_project_id_bigint_idx,
      columns: [:status, :created_at, :project_id_convert_to_bigint],
      options: { where: "type::text = 'Ci::Build'::text" }
    }
  ]
  TABLE_NAME = :p_ci_builds

  def up
    INDEXES.each do |definition|
      name, columns, options = definition.values_at(:name, :columns, :options)
      add_concurrent_partitioned_index(TABLE_NAME, columns, name: name, **(options || {}))
    end
  end

  def down
    INDEXES.each do |definition|
      remove_concurrent_partitioned_index_by_name(TABLE_NAME, definition[:name])
    end
  end
end
