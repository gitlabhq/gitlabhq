# frozen_string_literal: true

class SwapColumnsForDeploymentsBigintConversionPhaseTwo < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.3'

  TABLE_NAME = 'deployments'
  COLUMNS = %w[project_id user_id].freeze
  INDEXES = %w[
    index_deployments_on_archived_project_id_iid
    index_deployments_on_project_and_environment_and_updated_at_id
    index_deployments_on_project_and_finished
    index_deployments_on_project_id_and_id
    index_deployments_on_project_id_and_iid
    index_deployments_on_project_id_and_status_and_created_at
    index_deployments_on_project_id_and_updated_at_and_id
  ].freeze
  SM_ONLY_INDEX = %w[index_deployments_on_user_id_and_status_and_created_at].freeze

  # The primary key is already `bigint` after phase one, so no inbound foreign
  # key is affected here and only the outbound one needs its name swapped.
  # `user_id` intentionally has no foreign key.
  OUTBOUND_FOREIGN_KEYS = %w[fk_b9a3851b82].freeze

  def up
    return unless bigint_columns_all_exist?
    return unless bigint_columns_match_type?('bigint')

    swap
  end

  def down
    return unless bigint_columns_all_exist?
    return unless bigint_columns_match_type?('integer')

    swap
  end

  private

  def swap
    unless can_execute_on?(:deployments)
      raise StandardError,
        "Wraparound prevention vacuum detected on deployments table. Please try again later."
    end

    with_lock_retries(raise_on_exhaustion: true) do
      COLUMNS.each do |column|
        swap_columns(TABLE_NAME, column, convert_to_bigint_column(column))
      end

      # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
      reset_all_trigger_functions(TABLE_NAME)
      # rubocop:enable Migration/WithLockRetriesDisallowedMethod

      INDEXES.each { |index| swap_index_if_exists(index) }

      SM_ONLY_INDEX.each { |index| swap_index_if_exists(index) } unless Gitlab.com_except_jh?

      OUTBOUND_FOREIGN_KEYS.each do |foreign_key|
        swap_foreign_keys(TABLE_NAME, foreign_key, tmp_name(foreign_key))
      end
    end
  end

  # `swap_indexes` renames unconditionally, which raises when either index is
  # absent. Phase one hit this in production and was patched three times, so we
  # guard every index up front rather than only the self-managed-only one.
  # See https://gitlab.com/gitlab-org/gitlab/-/commit/e815601278ff1f9da21f651805f56ab03172f36f
  def swap_index_if_exists(index)
    bigint_idx_name = bigint_index_name(index)

    unless index_exists_by_name?(TABLE_NAME, index) && index_exists_by_name?(TABLE_NAME, bigint_idx_name)
      say "Skipping swap for non-existent index: #{index} or bigint: #{bigint_idx_name}"
      return
    end

    swap_indexes(TABLE_NAME, index, bigint_idx_name)
  end

  def tmp_name(name)
    "#{name}_tmp"
  end

  def bigint_columns_all_exist?
    if COLUMNS.all? { |column| column_exists?(TABLE_NAME, convert_to_bigint_column(column)) }
      true
    else
      say "Not all conversion columns found - migration skipped"
      false
    end
  end

  def bigint_columns_match_type?(column_type)
    if COLUMNS.all? { |column| column_for(TABLE_NAME, convert_to_bigint_column(column)).sql_type == column_type }
      true
    else
      say "Columns do not match type - migration skipped"
      false
    end
  end
end
