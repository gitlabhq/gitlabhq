# frozen_string_literal: true

class AddCreatedByIdToCdVersionSets < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  def up
    with_lock_retries do
      add_column :cd_version_sets, :created_by_id, :bigint, if_not_exists: true
    end

    add_concurrent_foreign_key :cd_version_sets, :users, column: :created_by_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_version_sets, column: :created_by_id
      remove_column :cd_version_sets, :created_by_id, if_exists: true
    end
  end
end
