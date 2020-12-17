# frozen_string_literal: true

class CleanupTransferedProjectsSharedRunners < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 25_000
  INTERVAL = 3.minutes
  MIGRATION = 'ResetSharedRunnersForTransferredProjects'

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    include EachBatch

    self.table_name = 'namespaces'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Namespace,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # This migration fixes an inconsistent database state resulting from https://gitlab.com/gitlab-org/gitlab/-/issues/271728
    # and as such does not require a down migration
  end
end
