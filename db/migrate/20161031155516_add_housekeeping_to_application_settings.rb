# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddHousekeepingToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :housekeeping_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:application_settings, :housekeeping_bitmaps_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:application_settings, :housekeeping_incremental_repack_period, :integer, default: 10, allow_null: false)
    add_column_with_default(:application_settings, :housekeeping_full_repack_period, :integer, default: 50, allow_null: false)
    add_column_with_default(:application_settings, :housekeeping_gc_period, :integer, default: 200, allow_null: false)
  end

  def down
    remove_column(:application_settings, :housekeeping_enabled, :boolean, default: true, allow_null: false)
    remove_column(:application_settings, :housekeeping_bitmaps_enabled, :boolean, default: true, allow_null: false)
    remove_column(:application_settings, :housekeeping_incremental_repack_period, :integer, default: 10, allow_null: false)
    remove_column(:application_settings, :housekeeping_full_repack_period, :integer, default: 50, allow_null: false)
    remove_column(:application_settings, :housekeeping_gc_period, :integer, default: 200, allow_null: false)
  end
end
