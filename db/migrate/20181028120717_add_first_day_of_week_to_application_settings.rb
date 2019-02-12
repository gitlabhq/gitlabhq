# frozen_string_literal: true

class AddFirstDayOfWeekToApplicationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:application_settings, :first_day_of_week, :integer, default: 0)
  end

  def down
    remove_column(:application_settings, :first_day_of_week)
  end
end
