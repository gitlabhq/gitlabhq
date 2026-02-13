# frozen_string_literal: true

class DropTmpBigintIndexesForDeploymentClusters < Gitlab::Database::Migration[2.3]
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

  def up
    return unless bigint_columns_all_exist?
    return unless bigint_columns_match_type?('integer')

    unless can_execute_on?(:deployment_clusters)
      raise StandardError,
        "Wraparound prevention vacuum detected on deployment_clusters table. Please try again later."
    end

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index))
    end

    with_lock_retries(raise_on_exhaustion: true) do
      remove_foreign_key_if_exists(
        :deployment_clusters,
        :deployments,
        name: :fk_rails_6359a164df_tmp,
        reverse_lock_order: true
      )
    end
  end

  def down; end

  private

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
