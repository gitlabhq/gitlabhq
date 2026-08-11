# frozen_string_literal: true

# The sharding key is copied from packages_package_files.project_id, a
# denormalized column with no foreign key of its own. Its parent packages_packages
# is cleaned up by a loose foreign key, so during a cleanup backlog package files
# hold the project_id of a deleted project. A hard FK here rejects those values
# and aborts the sharding key backfill.
# Rows are still cleaned up by the loose foreign key on package_file_id.
#
# This is a regular migration on purpose: it must run before the post-deploy
# finalize migration 20260420232456 when both ship in the same upgrade.
class RemoveProjectIdForeignKeyFromPackagesPackageFileStates < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_e568054097'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :packages_package_file_states, :projects,
        column: :project_id, name: CONSTRAINT_NAME
    end
  end

  # Once the FK is gone nothing enforces integrity on project_id, so orphaned values
  # may accumulate. add_concurrent_foreign_key validates the constraint it adds, so
  # this rollback fails against a database that has collected any. Delete the orphans
  # first if it needs to run.
  def down
    add_concurrent_foreign_key :packages_package_file_states, :projects,
      column: :project_id, on_delete: :cascade, name: CONSTRAINT_NAME, reverse_lock_order: true
  end
end
