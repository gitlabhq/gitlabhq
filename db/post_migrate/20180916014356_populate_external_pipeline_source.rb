# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateExternalPipelineSource < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  MIGRATION = 'PopulateExternalPipelineSource'.freeze
  BATCH_SIZE = 500

  disable_ddl_transaction!

  class Pipeline < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_pipelines'
  end

  def up
    Pipeline.where(source: nil).tap do |relation|
      queue_background_migration_jobs_by_range_at_intervals(relation,
                                                            MIGRATION,
                                                            5.minutes,
                                                            batch_size: BATCH_SIZE)
    end
  end

  def down
    # noop
  end
end
