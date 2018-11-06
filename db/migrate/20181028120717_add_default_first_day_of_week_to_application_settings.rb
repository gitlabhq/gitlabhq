# frozen_string_literal: true

class AddDefaultFirstDayOfWeekToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:application_settings, :default_first_day_of_week, :integer, default: 0)
  end

  def down
    remove_column(:application_settings, :default_first_day_of_week)
  end
end
