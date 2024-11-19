# frozen_string_literal: true

class SwapColumnsForPCiBuildsProjectId < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::MigrationHelpers::Swapping
  include ::Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.0'

  TABLE = :p_ci_builds
  COLUMNS = [
    { name: :project_id_convert_to_bigint, old_name: :project_id }
  ]
  TRIGGER_FUNCTION = :trigger_10ee1357e825
  INDEXES = [
    {
      name: :p_ci_builds_project_id_bigint_id_idx,
      columns: [:project_id_convert_to_bigint, :id],
      old_name: :p_ci_builds_project_id_id_idx
    },
    {
      name: :p_ci_builds_project_id_bigint_name_ref_idx,
      columns: [:project_id_convert_to_bigint, :name, :ref],
      options: { where: "type::text = 'Ci::Build'::text AND status::text = 'success'::text AND (retried = false OR retried IS NULL)" },
      old_name: :p_ci_builds_project_id_name_ref_idx
    },
    {
      name: :p_ci_builds_project_id_bigint_status_idx,
      columns: [:project_id_convert_to_bigint, :status],
      options: { where: "type::text = 'Ci::Build'::text AND (status::text = ANY (ARRAY['running'::character varying::text, 'pending'::character varying::text, 'created'::character varying::text]))" },
      old_name: :p_ci_builds_project_id_status_idx
    },
    {
      name: :p_ci_builds_status_created_at_project_id_bigint_idx,
      columns: [:status, :created_at, :project_id_convert_to_bigint],
      options: { where: "type::text = 'Ci::Build'::text" },
      old_name: :p_ci_builds_status_created_at_project_id_idx
    }
  ]

  def up
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      correct_integer_index_name
      swap
      remove_integer_indexes_and_rename_bigint
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    recover_integer_indexes

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      swap
      swap_indexes_for_project_id
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  private

  def swap
    lock_tables(TABLE)

    COLUMNS.each do |column|
      swap_columns(TABLE, column[:name], column[:old_name])
    end
    reset_trigger_function(TRIGGER_FUNCTION)
  end

  def correct_integer_index_name
    return if index_name_exists?(TABLE, :p_ci_builds_project_id_id_idx)

    # fix the difference between structure.sql and production
    rename_partitioned_index(TABLE, :p_ci_builds_project_id_id_convert_to_bigint_idx, :p_ci_builds_project_id_id_idx)
  end

  def remove_integer_indexes_and_rename_bigint
    INDEXES.each do |index_metadata|
      swap_partitioned_indexes(TABLE, index_metadata[:name], index_metadata[:old_name])
      remove_index(TABLE, name: index_metadata[:name], if_exists: true) # rubocop:disable Migration/RemoveIndex -- same as remove_concurrent_partitioned_index_by_name
    end
  end

  def swap_indexes_for_project_id
    INDEXES.each do |index_metadata|
      swap_partitioned_indexes(TABLE, index_metadata[:name], index_metadata[:old_name])
    end
  end

  def recover_integer_indexes
    INDEXES.each do |index_metadata|
      add_concurrent_partitioned_index(
        TABLE, index_metadata[:columns],
        name: index_metadata[:name], **index_metadata.fetch(:options, {})
      )
    end
  end
end
