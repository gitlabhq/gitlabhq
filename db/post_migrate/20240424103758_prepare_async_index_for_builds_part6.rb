# frozen_string_literal: true

class PrepareAsyncIndexForBuildsPart6 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'

  INDEXES = [
    {
      name: :p_ci_builds_user_id_created_at_idx_bigint,
      columns: [:user_id_convert_to_bigint, :created_at],
      options: { where: "type::text = 'Ci::Build'::text" }
    },
    {
      name: :p_ci_builds_user_id_idx_bigint,
      columns: [:user_id_convert_to_bigint]
    },
    {
      name: :p_ci_builds_user_id_name_created_at_idx_bigint,
      columns: [:user_id_convert_to_bigint, :name, :created_at],
      options: { where: "type::text = 'Ci::Build'::text AND (name::text = ANY (ARRAY['container_scanning'::character varying::text, 'dast'::character varying::text, 'dependency_scanning'::character varying::text, 'license_management'::character varying::text, 'license_scanning'::character varying::text, 'sast'::character varying::text, 'coverage_fuzzing'::character varying::text, 'apifuzzer_fuzz'::character varying::text, 'apifuzzer_fuzz_dnd'::character varying::text, 'secret_detection'::character varying::text]))" }
    },
    {
      name: :p_ci_builds_user_id_name_idx_bigint,
      columns: [:user_id_convert_to_bigint, :name],
      options: { where: "type::text = 'Ci::Build'::text AND (name::text = ANY (ARRAY['container_scanning'::character varying::text, 'dast'::character varying::text, 'dependency_scanning'::character varying::text, 'license_management'::character varying::text, 'license_scanning'::character varying::text, 'sast'::character varying::text, 'coverage_fuzzing'::character varying::text, 'secret_detection'::character varying::text]))" }
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
