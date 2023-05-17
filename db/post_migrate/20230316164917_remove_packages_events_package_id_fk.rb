# frozen_string_literal: true

class RemovePackagesEventsPackageIdFk < Gitlab::Database::Migration[2.1]
  FK_NAME = 'fk_rails_c6c20d0094'
  SOURCE_TABLE = :packages_events
  TARGET_TABLE = :packages_packages
  COLUMN = :package_id

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE,
        TARGET_TABLE,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE,
      TARGET_TABLE,
      name: FK_NAME,
      column: COLUMN,
      on_delete: :nullify
    )
  end
end
