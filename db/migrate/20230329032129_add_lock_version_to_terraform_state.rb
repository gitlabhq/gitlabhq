# frozen_string_literal: true

class AddLockVersionToTerraformState < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :terraform_states, :activerecord_lock_version, :integer, null: false, default: 0
  end
end
