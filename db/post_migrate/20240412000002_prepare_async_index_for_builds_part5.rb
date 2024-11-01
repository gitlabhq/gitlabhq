# frozen_string_literal: true

class PrepareAsyncIndexForBuildsPart5 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'

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
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |definition|
        name, columns, options = definition.values_at(:name, :columns, :options)
        index_name = generated_index_name(partition.identifier, name)
        prepare_async_index partition.identifier, columns, name: index_name, **(options || {})
      end
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |definition|
        name, columns, options = definition.values_at(:name, :columns, :options)
        index_name = generated_index_name(partition.identifier, name)
        unprepare_async_index partition.identifier, columns, name: index_name, **(options || {})
      end
    end
  end
end
