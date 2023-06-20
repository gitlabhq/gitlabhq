# frozen_string_literal: true

class AddDefaultBranchProtectionsJsonToNamespaceSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :namespace_settings, :default_branch_protection_defaults, :jsonb, null: false, default: {}
  end
end
