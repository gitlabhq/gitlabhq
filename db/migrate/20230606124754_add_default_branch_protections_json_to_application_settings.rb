# frozen_string_literal: true

class AddDefaultBranchProtectionsJsonToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :default_branch_protection_defaults, :jsonb, null: false, default: {}
  end
end
