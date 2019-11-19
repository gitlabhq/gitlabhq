# frozen_string_literal: true

class AddProductivityAnalyticsStartDate < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :productivity_analytics_start_date, :datetime_with_timezone
  end
end
