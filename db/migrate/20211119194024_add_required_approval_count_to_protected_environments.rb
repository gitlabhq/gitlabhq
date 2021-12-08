# frozen_string_literal: true

class AddRequiredApprovalCountToProtectedEnvironments < Gitlab::Database::Migration[1.0]
  def change
    add_column :protected_environments, :required_approval_count, :integer, default: 0, null: false
  end
end
