class AddPagesSizeToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :application_settings, :max_pages_size, :integer, default: 100, allow_null: false
  end

  def down
    remove_column(:application_settings, :max_pages_size)
  end
end
