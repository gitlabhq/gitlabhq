# frozen_string_literal: true

class CreateBigintIndexesForDeploymentMergeRequests < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = 'deployment_merge_requests'
  COLUMNS = %i[deployment_id merge_request_id environment_id].freeze

  # Counterpart of the async index preparation in
  # 20251110180845_prepare_indexes_for_deployment_merge_request_bigint_columns.rb.
  # GitLab.com already has these indexes; this creates them for instances that
  # do not run async index creation.
  INDEXES = [
    {
      name: 'deployment_merge_requests_on_deployment_id_merge_request_id_pkey',
      columns: %i[deployment_id_convert_to_bigint merge_request_id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'idx_environment_merge_requests_unique_index',
      columns: %i[environment_id_convert_to_bigint merge_request_id_convert_to_bigint],
      options: { unique: true }
    },
    {
      name: 'index_deployment_merge_requests_on_merge_request_id',
      columns: %i[merge_request_id_convert_to_bigint]
    }
  ].freeze

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)
    return unless can_execute_on?(TABLE_NAME)

    # rubocop:disable Migration/PreventIndexCreation -- bigint migration, already created
    # asynchronously on GitLab.com by 20251110180845
    INDEXES.each do |index|
      add_concurrent_index(
        TABLE_NAME,
        index[:columns],
        name: bigint_index_name(index[:name]),
        **index.fetch(:options, {})
      )
    end
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)
    return unless can_execute_on?(TABLE_NAME)

    INDEXES.each do |index|
      remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(index[:name]))
    end
  end
end
