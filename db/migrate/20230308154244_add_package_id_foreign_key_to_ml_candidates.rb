# frozen_string_literal: true

class AddPackageIdForeignKeyToMlCandidates < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ml_candidates, :packages_packages, column: :package_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ml_candidates, column: :package_id
    end
  end
end
