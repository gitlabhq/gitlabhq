# frozen_string_literal: true

class BackfillSnippetRepositories < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 3.minutes
  BATCH_SIZE = 100
  MIGRATION = 'BackfillSnippetRepositories'

  disable_ddl_transaction!

  class Snippet < ActiveRecord::Base
    include EachBatch

    self.table_name = 'snippets'
    self.inheritance_column = :_type_disabled
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Snippet,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
