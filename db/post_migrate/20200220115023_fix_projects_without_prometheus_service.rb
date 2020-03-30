# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixProjectsWithoutPrometheusService < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 50_000
  MIGRATION = 'FixProjectsWithoutPrometheusService'

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Project, MIGRATION, 2.minutes, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
