# frozen_string_literal: true

class AddLockedByUserIdForeignKeyToTerraformState < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :terraform_states, :users, column: :locked_by_user_id
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :terraform_states, column: :locked_by_user_id
    end
  end
end
