# frozen_string_literal: true

class ScheduleCopyCiBuildsColumnsToSecurityScans < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    # no-op as we found an issue with bg migration, we fixed it and rescheduling it again.
  end

  def down
    # no-op
  end
end
