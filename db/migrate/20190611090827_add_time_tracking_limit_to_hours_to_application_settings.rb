# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTimeTrackingLimitToHoursToApplicationSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default :application_settings, :time_tracking_limit_to_hours, :boolean, default: false, allow_null: false
    # rubocop:enable Migration/AddColumnWithDefault
  end

  def down
    remove_column :application_settings, :time_tracking_limit_to_hours
  end
end
