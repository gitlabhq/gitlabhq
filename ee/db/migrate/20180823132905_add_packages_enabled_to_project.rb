# frozen_string_literal: true
class AddPackagesEnabledToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:projects, :packages_enabled, :boolean, default: true, allow_null: false)
  end

  def down
    if column_exists?(:projects, :packages_enabled)
      remove_column(:projects, :packages_enabled)
    end
  end
end
