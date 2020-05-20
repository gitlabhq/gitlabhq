# frozen_string_literal: true

class EnsureDeprecatedJenkinsServiceRecordsRemoval < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute <<~SQL.strip
      DELETE FROM services WHERE type = 'JenkinsDeprecatedService';
    SQL
  end

  def down
    # no-op

    # The records were removed by `up`
  end
end
