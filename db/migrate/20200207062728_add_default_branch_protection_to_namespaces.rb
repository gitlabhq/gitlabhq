# frozen_string_literal: true

class AddDefaultBranchProtectionToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    with_lock_retries do
      add_column :namespaces, :default_branch_protection, :integer, limit: 2
    end
  end
end
