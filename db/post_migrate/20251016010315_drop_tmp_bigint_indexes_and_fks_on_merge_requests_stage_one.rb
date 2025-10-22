# frozen_string_literal: true

class DropTmpBigintIndexesAndFksOnMergeRequestsStageOne < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %w[assignee_id merge_user_id updated_by_id milestone_id source_project_id].freeze

  INDEXES = [
    {
      name: 'index_merge_requests_on_assignee_id',
      columns: [:assignee_id_convert_to_bigint]
    },
    {
      name: 'index_merge_requests_on_merge_user_id',
      columns: [:merge_user_id_convert_to_bigint],
      options: { where: "merge_user_id_convert_to_bigint IS NOT NULL" }
    },
    {
      name: 'index_merge_requests_on_updated_by_id',
      columns: [:updated_by_id_convert_to_bigint],
      options: { where: "updated_by_id_convert_to_bigint IS NOT NULL" }
    },
    {
      name: 'index_merge_requests_on_milestone_id',
      columns: [:milestone_id_convert_to_bigint]
    },
    {
      name: 'idx_merge_requests_on_source_project_and_branch_state_opened',
      columns: [:source_project_id_convert_to_bigint, :source_branch],
      options: { where: "state_id = 1" }
    },
    {
      name: 'index_merge_requests_on_source_project_id_and_source_branch',
      columns: [:source_project_id_convert_to_bigint, :source_branch]
    }
  ].freeze

  FOREIGN_KEYS = [
    {
      source_table: :merge_requests,
      column: :assignee_id_convert_to_bigint,
      target_table: :users,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_6149611a04
    },
    {
      source_table: :merge_requests,
      column: :updated_by_id_convert_to_bigint,
      target_table: :users,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_641731faff
    },
    {
      source_table: :merge_requests,
      column: :milestone_id_convert_to_bigint,
      target_table: :milestones,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_6a5165a692
    },
    {
      source_table: :merge_requests,
      column: :merge_user_id_convert_to_bigint,
      target_table: :users,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_ad525e1f87
    },
    {
      source_table: :merge_requests,
      column: :source_project_id_convert_to_bigint,
      target_table: :projects,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_source_project
    }
  ].freeze

  def up
    vacuum_detection
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index[:name]))
    end

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      FOREIGN_KEYS.each do |foreign_key|
        remove_foreign_key_if_exists(
          foreign_key[:source_table],
          foreign_key[:target_table],
          name: tmp_name(foreign_key[:name]),
          reverse_lock_order: true
        )
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
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
        reverse_lock_order: true
      )
    end
  end

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
