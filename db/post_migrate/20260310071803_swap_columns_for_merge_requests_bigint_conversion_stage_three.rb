# frozen_string_literal: true

class SwapColumnsForMergeRequestsBigintConversionStageThree < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers

  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %w[id author_id].freeze

  PRIMARY_KEY = {
    name: 'merge_requests_pkey',
    columns: [:id_convert_to_bigint],
    options: { unique: true }
  }

  INDEXES = %w[
    idx_merge_requests_on_id_and_merge_jid
    idx_merge_requests_on_merged_state
    idx_merge_requests_on_unmerged_state_id
    index_merge_requests_on_author_id_and_id
    index_merge_requests_on_author_id_and_created_at
    idx_mrs_on_target_id_and_created_at_and_state_id
    index_merge_requests_on_target_project_id_and_created_at_and_id
    index_merge_requests_on_target_project_id_and_updated_at_and_id
    index_merge_requests_on_tp_id_and_merge_commit_sha_and_id
    index_on_merge_requests_for_latest_diffs
    index_merge_requests_on_author_id_and_target_project_id
  ].freeze

  FOREIGN_KEYS = [
    {
      source_table: :merge_requests,
      column: :author_id_convert_to_bigint,
      target_table: :users,
      target_column: :id,
      on_delete: :nullify,
      name: :fk_e719a85f8a,
      reverse_lock_order: false
    },
    {
      source_table: :environments,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :nullify,
      name: :fk_01a033a308,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_assignment_events,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_08f7602bfd,
      reverse_lock_order: true
    },
    {
      source_table: :scan_result_policy_violations,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_17ce579abf,
      reverse_lock_order: true
    },
    {
      source_table: :merge_requests_compliance_violations,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_290ec1ab02,
      reverse_lock_order: true
    },
    {
      source_table: :approvals,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_310d714958,
      reverse_lock_order: true
    },
    {
      source_table: :agent_activity_events,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :nullify,
      name: :fk_3af186389b,
      reverse_lock_order: true
    },
    {
      source_table: :merge_requests_approval_rules_merge_requests,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_74e3466397,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_diffs,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_8483f3258f,
      reverse_lock_order: true
    },
    {
      source_table: :security_policy_dismissals,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_bc10da1827,
      reverse_lock_order: true
    },
    {
      source_table: :duo_workflows_workflows,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_ed58162ace,
      reverse_lock_order: true
    },
    {
      source_table: :status_check_responses,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_f3953d86c6,
      reverse_lock_order: true
    },
    {
      source_table: :approval_policy_merge_request_bypass_events,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_f39e177609,
      reverse_lock_order: true
    },
    {
      source_table: :approval_merge_request_rules,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_004ce82224,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_context_commits,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_0fe0039f60,
      reverse_lock_order: true
    },
    {
      source_table: :description_versions,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_12b144011c,
      reverse_lock_order: true
    },
    {
      source_table: :resource_state_events,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_3112bba7dc,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_blocks,
      column: :blocked_merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_364d4bea8b,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_assignees,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_443443ce6f,
      reverse_lock_order: true
    },
    {
      source_table: :merge_requests_closing_issues,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_458eda8667,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_merge_schedules,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_5294434bc3,
      reverse_lock_order: true
    },
    {
      source_table: :reviews,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_5ca11d8c31,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_approval_metrics,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_5cb1ca73f8,
      reverse_lock_order: true
    },
    {
      source_table: :resource_iteration_events,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_6830c13ac1,
      reverse_lock_order: true
    },
    {
      source_table: :resource_state_events,
      column: :source_merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :nullify,
      name: :fk_rails_7ddc5f7457,
      reverse_lock_order: true
    },
    {
      source_table: :deployment_merge_requests,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_86a6d8bf12,
      reverse_lock_order: true
    },
    {
      source_table: :excluded_merge_requests,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_8c973feffa,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_cleanup_schedules,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_92dd0e705c,
      reverse_lock_order: true
    },
    {
      source_table: :resource_label_events,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_9851a00031,
      reverse_lock_order: true
    },
    {
      source_table: :resource_milestone_events,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_a006df5590,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_user_mentions,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_aa1b2961b1,
      reverse_lock_order: true
    },
    {
      source_table: :merge_trains,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_b374b5225d,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_predictions,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_b3b78cbcd0,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_reviewers,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_d9fec24b9d,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_metrics,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_e6d7c24d1b,
      reverse_lock_order: true
    },
    {
      source_table: :draft_notes,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_e753681674,
      reverse_lock_order: true
    },
    {
      source_table: :merge_request_blocks,
      column: :blocking_merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_e9387863bc,
      reverse_lock_order: true
    },
    {
      source_table: :timelogs,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_timelogs_merge_requests_merge_request_id,
      reverse_lock_order: true
    }
  ].freeze
  PARTITIONED_FOREIGN_KEYS = [
    {
      source_table: :merge_requests_merge_data,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_593f9b7924,
      reverse_lock_order: true
    }
  ].freeze

  def up
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('bigint')

    swap
  end

  def down
    return if skip_migration_as_bigint_columns_non_exist || skip_migration_as_bigint_columns_type_non_match('integer')

    swap

    restore_pk_and_fks
  end

  private

  def swap
    unless can_execute_on?(:merge_requests)
      raise StandardError,
        "Wraparound prevention vacuum detected on merge_requests table" \
          "Please try again later."
    end

    restore_pk_and_fks
    replace_foreign_keys

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    with_lock_retries(raise_on_exhaustion: true) do
      COLUMNS.each do |column|
        swap_columns(TABLE_NAME, column, convert_to_bigint_column(column))
      end
      swap_columns_default(TABLE_NAME, 'id', convert_to_bigint_column('id'))

      reset_all_trigger_functions(TABLE_NAME)

      INDEXES.each do |index|
        bigint_idx_name = bigint_index_name(index)
        swap_indexes(TABLE_NAME, index, bigint_idx_name)
      end

      # Swap PK constraint
      drop_constraint(TABLE_NAME, PRIMARY_KEY[:name], cascade: true)
      rename_index(TABLE_NAME, bigint_index_name(PRIMARY_KEY[:name]), PRIMARY_KEY[:name])
      add_primary_key_using_index(TABLE_NAME, PRIMARY_KEY[:name], PRIMARY_KEY[:name])
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  # Add dropped bigint PK index and FKs when reverse swap
  def restore_pk_and_fks
    # rubocop:disable Migration/PreventIndexCreation -- bigint migration
    add_concurrent_index TABLE_NAME, PRIMARY_KEY[:columns], name: bigint_index_name(PRIMARY_KEY[:name]),
      if_not_exists: true, **PRIMARY_KEY[:options]
    # rubocop:enable Migration/PreventIndexCreation

    FOREIGN_KEYS.each do |fk|
      next if foreign_key_replaced?(fk)

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
      next if foreign_key_replaced?(fk)

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

  # rubocop:disable Metrics/AbcSize -- custom implementation
  def replace_foreign_keys
    FOREIGN_KEYS.each do |fk|
      original_column = convert_bigint_column_to_original(fk[:column])
      original_target_column = convert_bigint_column_to_original(fk[:target_column])
      temporary_name = tmp_name(fk[:name])

      next if foreign_key_replaced?(fk)

      with_lock_retries do
        # Explicitly lock table in order of parent, child to attempt to avoid deadlocks
        tables = [fk[:source_table], fk[:target_table]]
        tables = tables.reverse if fk[:reverse_lock_order]
        execute "LOCK TABLE #{tables[0]}, #{tables[1]} IN ACCESS EXCLUSIVE MODE"

        if foreign_key_exists?(
          fk[:source_table],
          fk[:target_table],
          column: original_column,
          primary_key: original_target_column,
          name: fk[:name]
        )
          remove_foreign_key(
            fk[:source_table],
            fk[:target_table],
            column: original_column,
            primary_key: original_target_column,
            name: fk[:name]
          )
          rename_constraint(fk[:source_table], temporary_name, fk[:name])
        else
          remove_foreign_key_if_exists(
            fk[:source_table],
            fk[:target_table],
            column: fk[:column],
            primary_key: fk[:target_column],
            name: temporary_name
          )
        end
      end
    end

    PARTITIONED_FOREIGN_KEYS.each do |fk|
      original_column = convert_bigint_column_to_original(fk[:column])
      original_target_column = convert_bigint_column_to_original(fk[:target_column])
      temporary_name = tmp_name(fk[:name])

      next if foreign_key_replaced?(fk)

      if foreign_key_exists?(
        fk[:source_table],
        fk[:target_table],
        column: original_column,
        primary_key: original_target_column,
        name: fk[:name]
      )
        swap_partitioned_foreign_keys(fk[:source_table], fk[:name], temporary_name)
        remove_partitioned_foreign_key(
          fk[:source_table],
          fk[:target_table],
          column: original_column,
          name: temporary_name
        )
      else
        remove_partitioned_foreign_key(
          fk[:source_table],
          fk[:target_table],
          column: fk[:column],
          name: temporary_name
        )
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def tmp_name(name)
    "#{name}_tmp"
  end

  def convert_bigint_column_to_original(column)
    column.to_s.sub('_convert_to_bigint', '').to_sym
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

  def foreign_key_replaced?(fk)
    foreign_key_exists?(
      fk[:source_table],
      fk[:target_table],
      column: fk[:column],
      primary_key: fk[:target_column],
      name: fk[:name]
    )
  end
end
