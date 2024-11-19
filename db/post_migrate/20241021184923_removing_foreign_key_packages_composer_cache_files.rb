# frozen_string_literal: true

class RemovingForeignKeyPackagesComposerCacheFiles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  FROM_TABLE = :packages_composer_cache_files
  TO_TABLE = :namespaces
  FK_NAME = :fk_rails_b82cea43a0
  COLUMN = :namespace_id
  ON_DELETE = :nullify

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(FROM_TABLE, TO_TABLE, name: FK_NAME)
    end
  end

  def down
    add_concurrent_foreign_key(FROM_TABLE, TO_TABLE, name: FK_NAME, column: COLUMN, on_delete: ON_DELETE)
  end
end
