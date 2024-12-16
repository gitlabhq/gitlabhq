# frozen_string_literal: true

class RemoveMigrateMembershipsColumn < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    remove_column :bulk_import_configurations, :migrate_memberships
  end

  def down
    add_column :bulk_import_configurations, :migrate_memberships, :boolean, default: true, null: false
  end
end
