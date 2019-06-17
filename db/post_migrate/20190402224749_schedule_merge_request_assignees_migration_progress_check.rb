# frozen_string_literal: true

class ScheduleMergeRequestAssigneesMigrationProgressCheck < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  MIGRATION = 'MergeRequestAssigneesMigrationProgressCheck'.freeze

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    BackgroundMigrationWorker.perform_async(MIGRATION)
  end

  def down
  end
end
