# frozen_string_literal: true

class AddForeignKeyToPackagesComposerPackagesCreatorId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :packages_composer_packages

  def up
    add_concurrent_foreign_key TABLE_NAME, :users, column: :creator_id, on_delete: :nullify,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, column: :creator_id, reverse_lock_order: true
    end
  end
end
