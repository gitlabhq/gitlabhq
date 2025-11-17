# frozen_string_literal: true

class PrepareIndexesForDeploymentMergeRequestBigintColumns < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '18.6'
  disable_ddl_transaction!

  TABLE_NAME = 'deployment_merge_requests'
  BIGINT_COLUMNS = [
    :deployment_id_convert_to_bigint,
    :merge_request_id_convert_to_bigint,
    :environment_id_convert_to_bigint
  ].freeze

  INDEXES = [
    {
      name: 'deployment_merge_requests_on_deployment_id_merge_request_id_pkey',
      columns: [:deployment_id_convert_to_bigint, :merge_request_id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'idx_environment_merge_requests_unique_index',
      columns: [:environment_id_convert_to_bigint, :merge_request_id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'index_deployment_merge_requests_on_merge_request_id',
      columns: [:merge_request_id_convert_to_bigint]
    }
  ].freeze

  def up
    return if skip_migration?

    # rubocop:disable Migration/PreventIndexCreation -- Bigint migration
    INDEXES.each do |index|
      options = index[:options] || {}
      prepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
    end
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    return if skip_migration?

    INDEXES.each do |index|
      options = index[:options] || {}
      unprepare_async_index(TABLE_NAME, index[:columns], name: bigint_index_name(index[:name]), **options)
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
