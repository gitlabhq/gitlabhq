# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class BackfillDeploymentClustersFromDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'BackfillDeploymentClustersFromDeployments'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  class Deployment < ActiveRecord::Base
    include EachBatch

    default_scope { where.not(cluster_id: nil) } # rubocop:disable Cop/DefaultScope

    self.table_name = 'deployments'
  end

  def up
    say "Scheduling `#{MIGRATION}` jobs"

    queue_background_migration_jobs_by_range_at_intervals(Deployment, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # NOOP
  end
end
