class FixDevTimezoneSchema < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # The this migrations tries to help solve unwanted changes to `schema.rb`
  # while developing GitLab. Installations created before we started using
  # `datetime_with_timezone` are likely to face this problem. Updating those
  # columns to the new type should help fix this.

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  TIMEZONE_TABLES = %i(appearances ci_group_variables ci_pipeline_schedule_variables events gpg_keys gpg_signatures project_auto_devops)

  def up
    return unless Rails.env.development? || Rails.env.test?

    TIMEZONE_TABLES.each do |table|
      change_column table, :created_at, :datetime_with_timezone
      change_column table, :updated_at, :datetime_with_timezone
    end
  end

  def down
  end
end
