# frozen_string_literal: true

class SwapColumnsForUpstreamPipelineIdBetweenCiBuildsAndCiPipelines < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::MigrationHelpers::Swapping
  include ::Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '16.11'

  TABLE = :p_ci_builds
  REFERENCING_TABLE = :ci_pipelines
  COLUMNS = [
    { name: :upstream_pipeline_id_convert_to_bigint, old_name: :upstream_pipeline_id },
    { name: :commit_id_convert_to_bigint, old_name: :commit_id }
  ]
  TRIGGER_FUNCTION = :trigger_10ee1357e825
  FKS = [
    { name: :fk_6b6c3f3e70, column: :upstream_pipeline_id_convert_to_bigint, old_name: :fk_87f4cefcda },
    { name: :fk_8d588a7095, column: :commit_id_convert_to_bigint, old_name: :fk_d3130c9a7f }
  ]
  INDEXES = [
    {
      name: :p_ci_builds_upstream_pipeline_id_bigint_idx,
      columns: [:upstream_pipeline_id_convert_to_bigint],
      options: { where: 'upstream_pipeline_id_convert_to_bigint IS NOT NULL' },
      old_name: :p_ci_builds_upstream_pipeline_id_idx
    },
    {
      name: :p_ci_builds_commit_id_bigint_artifacts_expire_at_id_idx,
      columns: [:commit_id_convert_to_bigint, :artifacts_expire_at, :id],
      options: {
        where: "type::text = 'Ci::Build'::text AND (retried = false OR retried IS NULL) AND (name::text = ANY (ARRAY['sast'::character varying::text, 'secret_detection'::character varying::text, 'dependency_scanning'::character varying::text, 'container_scanning'::character varying::text, 'dast'::character varying::text]))"
      },
      old_name: :p_ci_builds_commit_id_artifacts_expire_at_id_idx
    },
    {
      name: :p_ci_builds_commit_id_bigint_stage_idx_created_at_idx,
      columns: [:commit_id_convert_to_bigint, :stage_idx, :created_at],
      old_name: :p_ci_builds_commit_id_stage_idx_created_at_idx
    },
    {
      name: :p_ci_builds_commit_id_bigint_status_type_idx,
      columns: [:commit_id_convert_to_bigint, :status, :type],
      old_name: :p_ci_builds_commit_id_status_type_idx
    },
    {
      name: :p_ci_builds_commit_id_bigint_type_name_ref_idx,
      columns: [:commit_id_convert_to_bigint, :type, :name, :ref],
      old_name: :p_ci_builds_commit_id_type_name_ref_idx
    },
    {
      name: :p_ci_builds_commit_id_bigint_type_ref_idx,
      columns: [:commit_id_convert_to_bigint, :type, :ref],
      old_name: :p_ci_builds_commit_id_type_ref_idx
    },
    {
      name: :p_ci_builds_resource_group_id_status_commit_id_bigint_idx,
      columns: [:resource_group_id, :status, :commit_id_convert_to_bigint],
      options: { where: 'resource_group_id IS NOT NULL' },
      old_name: :p_ci_builds_resource_group_id_status_commit_id_idx
    }
  ]

  def up
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      swap
      remove_integer_indexes_and_foreign_keys_and_rename_bigint
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    recover_integer_indexes_and_foreign_keys

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      swap
      swap_indexes_and_foreign_keys
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  private

  def swap
    lock_tables(REFERENCING_TABLE, TABLE)

    COLUMNS.each do |column|
      swap_columns(TABLE, column[:name], column[:old_name])
    end
    reset_trigger_function(TRIGGER_FUNCTION)
  end

  def remove_integer_indexes_and_foreign_keys_and_rename_bigint
    FKS.each do |fk_metadata|
      remove_foreign_key_if_exists(TABLE, REFERENCING_TABLE, column: fk_metadata[:column], reverse_lock_order: true)

      rename_partitioned_foreign_key(TABLE, fk_metadata[:name], fk_metadata[:old_name])
    end

    INDEXES.each do |index_metadata|
      old_index_name = old_index_name_from(index_metadata)
      if old_index_name.nil?
        rename_partitioned_index(TABLE, index_metadata[:name], index_metadata[:old_name])
      else
        if old_index_name != index_metadata[:old_name]
          # rename the index to the name we expect
          execute "ALTER INDEX #{old_index_name} RENAME TO #{index_metadata[:old_name]}"
        end

        swap_partitioned_indexes(TABLE, index_metadata[:name], index_metadata[:old_name])
      end

      remove_index(TABLE, name: index_metadata[:name], if_exists: true) # rubocop:disable Migration/RemoveIndex -- same as remove_concurrent_partitioned_index_by_name
    end
  end

  def swap_indexes_and_foreign_keys
    FKS.each do |fk_metadata|
      swap_partitioned_foreign_keys(TABLE, fk_metadata[:name], fk_metadata[:old_name])
    end

    INDEXES.each do |index_metadata|
      swap_partitioned_indexes(TABLE, index_metadata[:name], index_metadata[:old_name])
    end
  end

  def recover_integer_indexes_and_foreign_keys
    INDEXES.each do |index_metadata|
      add_concurrent_partitioned_index(
        TABLE, index_metadata[:columns],
        name: index_metadata[:name], **index_metadata.fetch(:options, {})
      )
    end

    FKS.each do |fk_metadata|
      add_concurrent_partitioned_foreign_key(
        TABLE, REFERENCING_TABLE,
        column: fk_metadata[:column], name: fk_metadata[:name], on_delete: :cascade, reverse_lock_order: true
      )
    end
  end

  def old_index_name_from(index_metadata)
    return index_metadata[:old_name] if index_name_exists?(TABLE, index_metadata[:old_name])

    old_index_columns = index_metadata[:columns].map(&:to_s)
    existing_old_index =
      indexes(TABLE).find { |index| index.columns == old_index_columns }
    existing_old_index.name.to_sym if existing_old_index.present?
  end
end
