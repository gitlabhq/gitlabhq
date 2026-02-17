# frozen_string_literal: true

class AddUsersUniqueConfirmationTokenPerOrganization < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  INDEX_NAME = 'index_users_on_organization_id_and_confirmation_token'

  # rubocop:disable Migration/PreventIndexCreation -- modifying an existing index to support Cells sharding
  def up
    add_concurrent_index :users, [:organization_id, :confirmation_token], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :users, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation
end
