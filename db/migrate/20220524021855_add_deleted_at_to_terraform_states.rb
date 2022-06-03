# frozen_string_literal: true

class AddDeletedAtToTerraformStates < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :terraform_states, :deleted_at, :datetime_with_timezone
  end
end
