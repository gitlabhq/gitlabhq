# frozen_string_literal: true

class CreateMissingFkAndAnalyzePCiBuildNeeds < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.11'

  SOURCE_TABLE = :p_ci_build_needs
  TARGET_TABLE = :p_ci_builds
  COLUMNS = %i[partition_id build_id].freeze
  TARGET_COLUMNS = %i[partition_id id].freeze
  FK_NAME = :fk_rails_3cf221d4ed_p

  def up
    add_concurrent_partitioned_foreign_key( # rubocop:disable Migration/PreventForeignKeyCreation -- part of the partitioning process
      SOURCE_TABLE,
      TARGET_TABLE,
      column: COLUMNS,
      target_column: TARGET_COLUMNS,
      name: FK_NAME,
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
    )
  end

  def down
    remove_partitioned_foreign_key(
      SOURCE_TABLE,
      TARGET_TABLE,
      name: FK_NAME,
      reverse_lock_order: true
    )
  end
end
