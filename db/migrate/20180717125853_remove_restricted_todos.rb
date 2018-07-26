# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
# frozen_string_literal: true

class RemoveRestrictedTodos < ActiveRecord::Migration
  DOWNTIME = false
  disable_ddl_transaction!

  MIGRATION = 'RemoveRestrictedTodos'.freeze
  BATCH_SIZE = 1000
  DELAY_INTERVAL = 5.minutes.to_i

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    Project.where('EXISTS (SELECT 1 FROM todos WHERE todos.project_id = projects.id)')
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * DELAY_INTERVAL, MIGRATION, range)
    end
  end

  def down
    # nothing to do
  end
end
