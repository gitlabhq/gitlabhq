# frozen_string_literal: true

class SwapColumnsForDeploymentsBigintConversionPhaseOne < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = 'deployments'
  COLUMNS = %w[id environment_id].freeze
  INDEXES = %w[
    index_deployments_for_visible_scope
    index_deployments_on_environment_id_and_id
    index_deployments_on_environment_id_and_ref
    index_deployments_on_environment_id_status_and_finished_at
    index_deployments_on_environment_id_status_and_id
    index_deployments_on_environment_status_sha
    index_deployments_on_project_and_environment_and_updated_at_id
    index_deployments_on_project_id_and_id
    index_deployments_on_project_id_and_updated_at_and_id
  ].freeze
  SM_ONLY_INDEX = %w[index_deployments_on_id_and_status_and_created_at].freeze

  # Outbound FK on deployments itself both survive CASCADE, so we swap names
  OUTBOUND_FOREIGN_KEYS = %w[fk_009fd21147].freeze

  # Inbound FKs from other tables referencing deployments(id).
  # CASCADE on the pkey drop destroys the originals; the _tmp versions
  # (referencing the bigint column) survive and just need renaming.
  # deployment_clusters is excluded its swap migration already renamed the FK.
  INBOUND_FOREIGN_KEYS = [
    { table: 'deployment_approvals', tmp_name: 'fk_2d060dfc73_tmp', final_name: 'fk_2d060dfc73' },
    { table: 'job_environments', tmp_name: 'fk_8729424205_tmp', final_name: 'fk_8729424205' },
    { table: 'deployment_merge_requests', tmp_name: 'fk_dcbce9f4df_tmp', final_name: 'fk_rails_dcbce9f4df' }
  ].freeze

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

      swap_columns_default(TABLE_NAME, 'id_convert_to_bigint', 'id')

      swap_pkey_index
      # rubocop:enable Migration/WithLockRetriesDisallowedMethod

      INDEXES.each do |index|
        bigint_idx_name = bigint_index_name(index)
        swap_indexes(TABLE_NAME, index, bigint_idx_name)
      end

      unless Gitlab.com_except_jh?
        SM_ONLY_INDEX.each do |index|
          bigint_idx_name = bigint_index_name(index)
          swap_indexes(TABLE_NAME, index, bigint_idx_name)
        end
      end

      # Outbound FKs: both original and _tmp survive CASCADE, swap their names
      OUTBOUND_FOREIGN_KEYS.each do |foreign_key|
        swap_foreign_keys(TABLE_NAME, foreign_key, tmp_name(foreign_key))
      end

      # Inbound FKs: originals were dropped by CASCADE, rename surviving _tmp versions
      INBOUND_FOREIGN_KEYS.each do |fk|
        rename_constraint(fk[:table], fk[:tmp_name], fk[:final_name])
      end
    end
  end

  # Manually swap due to primary key constraint
  def swap_pkey_index
    bigint_index_name = bigint_index_name("deployment_id_pkey")

    execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT deployments_pkey CASCADE"
    rename_index TABLE_NAME, bigint_index_name, "deployments_pkey"
    execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT deployments_pkey PRIMARY KEY USING INDEX deployments_pkey"
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
