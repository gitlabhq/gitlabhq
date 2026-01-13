# frozen_string_literal: true

class DropTmpBigintIndexesAndFksOnMergeRequestsStageTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %w[target_project_id latest_merge_request_diff_id last_edited_by_id].freeze

  INDEXES = [
    {
      name: 'index_merge_requests_on_target_project_id_and_iid',
      columns: [:target_project_id_convert_to_bigint, :iid],
      options: { unique: true }
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_merged_commit_sha',
      columns: [:target_project_id_convert_to_bigint, :merged_commit_sha]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_source_branch',
      columns: [:target_project_id_convert_to_bigint, :source_branch]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_squash_commit_sha',
      columns: [:target_project_id_convert_to_bigint, :squash_commit_sha]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_target_branch',
      columns: [:target_project_id_convert_to_bigint, :target_branch],
      options: { where: "state_id = 1 AND merge_when_pipeline_succeeds = true" }
    },
    {
      name: 'index_merge_requests_for_latest_diffs_with_state_merged',
      columns: [:latest_merge_request_diff_id_convert_to_bigint, :target_project_id_convert_to_bigint],
      options: { where: "state_id = 3" }
    },
    {
      name: 'index_merge_requests_on_latest_merge_request_diff_id',
      columns: [:latest_merge_request_diff_id_convert_to_bigint]
    },
    {
      name: 'idx_mrs_on_target_id_and_created_at_and_state_id',
      columns: [:target_project_id_convert_to_bigint, :state_id, :created_at, :id]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_created_at_and_id',
      columns: [:target_project_id_convert_to_bigint, :created_at, :id]
    },
    {
      name: 'index_merge_requests_on_target_project_id_and_updated_at_and_id',
      columns: [:target_project_id_convert_to_bigint, :updated_at, :id]
    },
    {
      name: 'index_merge_requests_on_tp_id_and_merge_commit_sha_and_id',
      columns: [:target_project_id_convert_to_bigint, :merge_commit_sha, :id]
    },
    {
      name: 'index_merge_requests_on_author_id_and_target_project_id',
      columns: [:author_id, :target_project_id_convert_to_bigint]
    },
    {
      name: 'index_on_merge_requests_for_latest_diffs',
      columns: [:target_project_id_convert_to_bigint],
      options: { include: [:id, :latest_merge_request_diff_id_convert_to_bigint] }
    }
  ].freeze

  FOREIGN_KEYS = [
    {
      source_table: :merge_requests,
      column: :target_project_id_convert_to_bigint,
      target_table: :projects,
      target_column: :id,
      on_delete: :cascade,
      name: :fk_a6963e8447,
      reverse_lock_order: true
    },
    {
      source_table: :merge_requests,
      column: :latest_merge_request_diff_id_convert_to_bigint,
      target_table: :merge_request_diffs,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_06067f5644,
      reverse_lock_order: false
    }
  ].freeze
  PARTITIONED_FOREIGN_KEYS = [
    {
      source_table: :p_generated_ref_commits,
      column: [:project_id, :merge_request_iid],
      target_table: :merge_requests,
      target_column: [:target_project_id_convert_to_bigint, :iid],
      on_delete: :cascade,
      name: :fk_generated_ref_commits_merge_request_id,
      reverse_lock_order: true
    }
  ].freeze

  def up
    vacuum_detection
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      FOREIGN_KEYS.each do |foreign_key|
        remove_foreign_key_if_exists(
          foreign_key[:source_table],
          foreign_key[:target_table],
          name: tmp_name(foreign_key[:name]),
          reverse_lock_order: foreign_key[:reverse_lock_order]
        )
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    PARTITIONED_FOREIGN_KEYS.each do |foreign_key|
      remove_partitioned_foreign_key(
        foreign_key[:source_table],
        foreign_key[:target_table],
        name: tmp_name(foreign_key[:name]),
        reverse_lock_order: foreign_key[:reverse_lock_order]
      )
    end

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index[:name]))
    end
  end

  def down
    vacuum_detection
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    INDEXES.each do |index|
      options = index[:options] || {}
      add_concurrent_index TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options
    end

    FOREIGN_KEYS.each do |fk|
      add_concurrent_foreign_key(
        fk[:source_table],
        fk[:target_table],
        column: fk[:column],
        target_column: fk[:target_column],
        name: tmp_name(fk[:name]),
        on_delete: fk[:on_delete],
        validate: true,
        reverse_lock_order: fk[:reverse_lock_order]
      )
    end

    PARTITIONED_FOREIGN_KEYS.each do |fk|
      add_concurrent_partitioned_foreign_key(
        fk[:source_table],
        fk[:target_table],
        column: fk[:column],
        target_column: fk[:target_column],
        name: tmp_name(fk[:name]),
        on_delete: fk[:on_delete],
        validate: true,
        reverse_lock_order: fk[:reverse_lock_order]
      )
    end
  end

  private

  def tmp_name(name)
    "#{name}_tmp"
  end

  def skip_migration_as_bigint_columns_non_exist
    unless COLUMNS.all? { |column| column_exists?(TABLE_NAME, convert_to_bigint_column(column)) }
      say "No conversion columns found - migration skipped"
      return true
    end

    false
  end

  def skip_migration_as_bigint_columns_type_non_match(column_type)
    unless COLUMNS.all? { |column| column_for(TABLE_NAME, convert_to_bigint_column(column)).sql_type == column_type }
      say "Columns are converted - migration skipped"
      return true
    end

    false
  end

  def vacuum_detection
    return if can_execute_on?(:merge_requests)

    raise StandardError,
      "Wraparound prevention vacuum detected on merge_requests table" \
        "Please try again later."
  end
end
