# frozen_string_literal: true

class UpdateTerraformStatesLockedByUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_FOREIGN_KEY = 'fk_rails_558901b030'
  NEW_FOREIGN_KEY = 'fk_558901b030'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :terraform_states, :users,
      column: :locked_by_user_id, on_delete: :nullify, name: NEW_FOREIGN_KEY

    with_lock_retries do
      remove_foreign_key :terraform_states, :users, name: OLD_FOREIGN_KEY
    end
  end

  def down
    add_concurrent_foreign_key :terraform_states, :users,
      column: :locked_by_user_id, on_delete: nil, name: OLD_FOREIGN_KEY

    with_lock_retries do
      remove_foreign_key :terraform_states, :users, name: NEW_FOREIGN_KEY
    end
  end
end
