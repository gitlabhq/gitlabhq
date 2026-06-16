# frozen_string_literal: true

class AddFkCdVersionSetsToCdEnvironments < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'index_cd_version_sets_on_environment_id'

  def up
    add_concurrent_index :cd_version_sets, :environment_id, name: INDEX_NAME

    add_concurrent_foreign_key :cd_version_sets, :cd_environments,
      column: :environment_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_version_sets, column: :environment_id
    end

    remove_concurrent_index_by_name :cd_version_sets, INDEX_NAME
  end
end
