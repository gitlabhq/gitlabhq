# frozen_string_literal: true

class SwapColumnsForPCiBuildsUserId < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::MigrationHelpers::Swapping
  include ::Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.0'

  TABLE = :p_ci_builds
  COLUMNS = [
    { name: :user_id_convert_to_bigint, old_name: :user_id }
  ]
  TRIGGER_FUNCTION = :trigger_10ee1357e825
  INDEXES = [
    {
      name: :p_ci_builds_user_id_created_at_idx_bigint,
      old_name: :p_ci_builds_user_id_created_at_idx,
      columns: [:user_id_convert_to_bigint, :created_at],
      options: { where: "type::text = 'Ci::Build'::text" }
    },
    {
      name: :p_ci_builds_user_id_idx_bigint,
      old_name: :p_ci_builds_user_id_idx,
      columns: [:user_id_convert_to_bigint]
    },
    {
      name: :p_ci_builds_user_id_name_created_at_idx_bigint,
      old_name: :p_ci_builds_user_id_name_created_at_idx,
      columns: [:user_id_convert_to_bigint, :name, :created_at],
      options: { where: "type::text = 'Ci::Build'::text AND (name::text = ANY (ARRAY['container_scanning'::character varying::text, 'dast'::character varying::text, 'dependency_scanning'::character varying::text, 'license_management'::character varying::text, 'license_scanning'::character varying::text, 'sast'::character varying::text, 'coverage_fuzzing'::character varying::text, 'apifuzzer_fuzz'::character varying::text, 'apifuzzer_fuzz_dnd'::character varying::text, 'secret_detection'::character varying::text]))" }
    },
    {
      name: :p_ci_builds_user_id_name_idx_bigint,
      old_name: :p_ci_builds_user_id_name_idx,
      columns: [:user_id_convert_to_bigint, :name],
      options: { where: "type::text = 'Ci::Build'::text AND (name::text = ANY (ARRAY['container_scanning'::character varying::text, 'dast'::character varying::text, 'dependency_scanning'::character varying::text, 'license_management'::character varying::text, 'license_scanning'::character varying::text, 'sast'::character varying::text, 'coverage_fuzzing'::character varying::text, 'secret_detection'::character varying::text]))" }
    }
  ]

  def up
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
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
      swap_indexes_for_user_id
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

  def remove_integer_indexes_and_rename_bigint
    INDEXES.each do |index_metadata|
      swap_partitioned_indexes(TABLE, index_metadata[:name], index_metadata[:old_name])
      remove_index(TABLE, name: index_metadata[:name], if_exists: true) # rubocop:disable Migration/RemoveIndex -- same as remove_concurrent_partitioned_index_by_name
    end
  end

  def swap_indexes_for_user_id
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
