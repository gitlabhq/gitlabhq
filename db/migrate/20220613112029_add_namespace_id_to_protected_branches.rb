# frozen_string_literal: true

class AddNamespaceIdToProtectedBranches < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :protected_branches, :namespace_id, :bigint
  end
end
