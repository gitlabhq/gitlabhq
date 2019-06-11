# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTimeTrackingDisplayHoursOnlyToApplicationSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :time_tracking_display_hours_only, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :application_settings, :time_tracking_display_hours_only
  end
end
