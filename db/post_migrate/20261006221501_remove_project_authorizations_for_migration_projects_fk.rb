# frozen_string_literal: true

class RemoveProjectAuthorizationsForMigrationProjectsFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.6'

  TABLE_NAME = :project_authorizations_for_migration
  FK_NAME = :fk_rails_b91fc9995e

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects, column: :project_id, name: FK_NAME
    end
  end

  def down
    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id, on_delete: :cascade, name: FK_NAME
  end
end
