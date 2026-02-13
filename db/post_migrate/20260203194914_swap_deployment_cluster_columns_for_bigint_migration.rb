# frozen_string_literal: true

class SwapDeploymentClusterColumnsForBigintMigration < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::Swapping
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '18.10'

  TABLE_NAME = 'deployment_clusters'
  COLUMNS = %w[deployment_id cluster_id].freeze
  INDEXES = %w[
    idx_deployment_clusters_on_cluster_id_and_kubernetes_namespace
    index_deployment_clusters_on_cluster_id_and_deployment_id
  ].freeze
  FOREIGN_KEYS = %w[fk_rails_6359a164df].freeze

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
    unless can_execute_on?(:deployment_clusters)
      raise StandardError,
        "Wraparound prevention vacuum detected on deployment_clusters table. Please try again later."
    end

    with_lock_retries(raise_on_exhaustion: true) do
      COLUMNS.each do |column|
        swap_columns(TABLE_NAME, column, convert_to_bigint_column(column))
      end

      # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
      reset_all_trigger_functions(TABLE_NAME)

      swap_columns_default(TABLE_NAME, 'deployment_id_convert_to_bigint', 'deployment_id')
      swap_columns_default(TABLE_NAME, 'cluster_id_convert_to_bigint', 'cluster_id')

      swap_pkey_index
      # rubocop:enable Migration/WithLockRetriesDisallowedMethod

      INDEXES.each do |index|
        bigint_idx_name = bigint_index_name(index)
        swap_indexes(TABLE_NAME, index, bigint_idx_name)
      end

      FOREIGN_KEYS.each do |foreign_key|
        bigint_fk_temp_name = tmp_name(foreign_key)
        swap_foreign_keys(TABLE_NAME, foreign_key, bigint_fk_temp_name)
      end
    end
  end

  # Manually swap due to primary key constraint
  def swap_pkey_index
    bigint_index_name = bigint_index_name("deployment_clusters_pkey")

    execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT deployment_clusters_pkey CASCADE"
    rename_index TABLE_NAME, bigint_index_name, "deployment_clusters_pkey"
    execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT deployment_clusters_pkey " \
      "PRIMARY KEY USING INDEX deployment_clusters_pkey"
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
