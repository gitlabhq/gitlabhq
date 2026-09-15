# frozen_string_literal: true

class AddBigintFkForDeploymentMergeRequestsToEnvironments < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = 'deployment_merge_requests'
  TARGET_TABLE = :environments
  COLUMNS = %i[deployment_id merge_request_id environment_id].freeze
  FK_NAME = 'fk_a064ff4453_tmp'

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMNS)
    return unless can_execute_on?(TABLE_NAME, TARGET_TABLE)

    # rubocop:disable Migration/ForeignKeysToDestroyServiceTables -- duplicates the existing
    # fk_a064ff4453 on the bigint shadow column, so it introduces no new dependent records
    add_concurrent_foreign_key(
      TABLE_NAME,
      TARGET_TABLE,
      column: :environment_id_convert_to_bigint,
      target_column: :id,
      name: FK_NAME,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
    # rubocop:enable Migration/ForeignKeysToDestroyServiceTables
  end

  def down
    return unless can_execute_on?(TABLE_NAME, TARGET_TABLE)

    remove_foreign_key_if_exists(
      TABLE_NAME,
      TARGET_TABLE,
      name: FK_NAME,
      reverse_lock_order: true
    )
  end
end
