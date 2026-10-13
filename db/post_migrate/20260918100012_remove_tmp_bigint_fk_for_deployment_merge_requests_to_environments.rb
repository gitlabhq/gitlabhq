# frozen_string_literal: true

class RemoveTmpBigintFkForDeploymentMergeRequestsToEnvironments < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = 'deployment_merge_requests'
  TARGET_TABLE = :environments
  COLUMN = :environment_id
  FK_NAME = 'fk_a064ff4453_tmp'

  INDEX_SOURCE_NAME = 'idx_environment_merge_requests_unique_index'
  INDEX_COLUMNS = %i[environment_id merge_request_id].freeze

  def up
    return if skip_bigint_migration?(TABLE_NAME, [COLUMN])
    return unless can_execute_on?(TABLE_NAME, TARGET_TABLE)

    remove_foreign_key_if_exists(
      TABLE_NAME,
      TARGET_TABLE,
      name: FK_NAME,
      reverse_lock_order: true
    )

    remove_concurrent_index_by_name(TABLE_NAME, bigint_index_name(INDEX_SOURCE_NAME))
  end

  def down
    return if skip_bigint_migration?(TABLE_NAME, [COLUMN])
    return unless can_execute_on?(TABLE_NAME, TARGET_TABLE)

    add_concurrent_index(
      TABLE_NAME,
      INDEX_COLUMNS.map { |column| convert_to_bigint_column(column) },
      name: bigint_index_name(INDEX_SOURCE_NAME),
      unique: true
    )

    add_concurrent_foreign_key(
      TABLE_NAME,
      TARGET_TABLE,
      column: convert_to_bigint_column(COLUMN),
      target_column: :id,
      name: FK_NAME,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end
end
