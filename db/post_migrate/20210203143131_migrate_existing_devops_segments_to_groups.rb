# frozen_string_literal: true

# Data migration to migrate multi-selection segments into separate segments.
# Both tables involved are pretty-low traffic and the number
# of records in DB  cannot exceed 400
class MigrateExistingDevopsSegmentsToGroups < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    Gitlab::BackgroundMigration::MigrateDevopsSegmentsToGroups.new.perform
  end

  def down
  end
end
