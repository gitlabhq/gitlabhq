# frozen_string_literal: true

class AddTimestampSoftwarelicensespolicy < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_timestamps_with_timezone(:software_license_policies, null: true)
  end

  def down
    remove_timestamps(:software_license_policies)
  end
end
