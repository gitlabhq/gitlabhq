# frozen_string_literal: true

class AddFkCdVersionSetEntriesToCdVersionSets < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_concurrent_foreign_key :cd_version_set_entries, :cd_version_sets, column: :version_set_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_version_set_entries, column: :version_set_id
    end
  end
end
