# frozen_string_literal: true

class AddUsersForeignKeyToTerraformStateVersions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :terraform_state_versions, :users, column: :created_by_user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :terraform_state_versions, :users, column: :created_by_user_id
    end
  end
end
