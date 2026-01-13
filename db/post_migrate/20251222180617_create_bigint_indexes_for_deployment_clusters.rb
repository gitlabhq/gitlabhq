# frozen_string_literal: true

class CreateBigintIndexesForDeploymentClusters < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.8'

  TABLE_NAME = 'deployment_clusters'
  BIGINT_COLUMNS = [
    :deployment_id_convert_to_bigint,
    :cluster_id_convert_to_bigint
  ].freeze

  INDEXES = [
    {
      name: 'idx_deployment_clusters_on_cluster_id_and_kubernetes_namespace',
      columns: [:cluster_id_convert_to_bigint, :kubernetes_namespace]
    },
    {
      name: 'deployment_clusters_pkey',
      columns: [:deployment_id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'index_deployment_clusters_on_cluster_id_and_deployment_id',
      columns: [:cluster_id_convert_to_bigint, :deployment_id_convert_to_bigint],
      options: { unique: true }
    }
  ].freeze

  def up
    return if skip_migration?

    INDEXES.each do |index|
      options = index[:options] || {}
      add_concurrent_index TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options
    end
  end

  def down
    return if skip_migration?

    INDEXES.each do |index|
      remove_concurrent_index_by_name TABLE_NAME, bigint_index_name(index[:name])
    end
  end

  private

  def skip_migration?
    unless conversion_columns_exist?
      say "No conversion columns found - migration skipped"
      return true
    end

    false
  end

  def conversion_columns_exist?
    BIGINT_COLUMNS.all? { |column| column_exists?(TABLE_NAME, column) }
  end
end
