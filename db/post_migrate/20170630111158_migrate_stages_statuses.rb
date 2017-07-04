class MigrateStagesStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  STATUSES = { created: 0, pending: 1, running: 2, success: 3,
               failed: 4, canceled: 5, skipped: 6, manual: 7 }

  class Stage < ActiveRecord::Base
    self.table_name = 'ci_stages'
  end

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'

    scope :latest, -> { where(retried: [false, nil]) }
    scope :created, -> { where(status: 'created') }
    scope :running, -> { where(status: 'running') }
    scope :pending, -> { where(status: 'pending') }
    scope :success, -> { where(status: 'success') }
    scope :failed, -> { where(status: 'failed')  }
    scope :canceled, -> { where(status: 'canceled')  }
    scope :skipped, -> { where(status: 'skipped')  }
    scope :manual, -> { where(status: 'manual')  }

    scope :failed_but_allowed, -> do
      where(allow_failure: true, status: [:failed, :canceled])
    end

    scope :exclude_ignored, -> do
      where("allow_failure = ? OR status IN (?)",
        false, %w[created pending running success skipped])
    end

    def self.status_sql
      scope_relevant = latest.exclude_ignored
      scope_warnings = latest.failed_but_allowed

      builds = scope_relevant.select('count(*)').to_sql
      created = scope_relevant.created.select('count(*)').to_sql
      success = scope_relevant.success.select('count(*)').to_sql
      manual = scope_relevant.manual.select('count(*)').to_sql
      pending = scope_relevant.pending.select('count(*)').to_sql
      running = scope_relevant.running.select('count(*)').to_sql
      skipped = scope_relevant.skipped.select('count(*)').to_sql
      canceled = scope_relevant.canceled.select('count(*)').to_sql
      warnings = scope_warnings.select('count(*) > 0').to_sql

      <<-SQL.strip_heredoc
        (CASE
          WHEN (#{builds}) = (#{skipped}) AND (#{warnings}) THEN #{STATUSES[:success]}
          WHEN (#{builds}) = (#{skipped}) THEN #{STATUSES[:skipped]}
          WHEN (#{builds}) = (#{success}) THEN #{STATUSES[:success]}
          WHEN (#{builds}) = (#{created}) THEN #{STATUSES[:created]}
          WHEN (#{builds}) = (#{success}) + (#{skipped}) THEN #{STATUSES[:success]}
          WHEN (#{builds}) = (#{success}) + (#{skipped}) + (#{canceled}) THEN #{STATUSES[:canceled]}
          WHEN (#{builds}) = (#{created}) + (#{skipped}) + (#{pending}) THEN #{STATUSES[:pending]}
          WHEN (#{running}) + (#{pending}) > 0 THEN #{STATUSES[:running]}
          WHEN (#{manual}) > 0 THEN #{STATUSES[:manual]}
          WHEN (#{created}) > 0 THEN #{STATUSES[:running]}
          ELSE #{STATUSES[:failed]}
        END)
      SQL
    end
  end

  def up
    status_sql = Build
      .where('ci_builds.commit_id = ci_stages.pipeline_id')
      .where('ci_builds.stage = ci_stages.name')
      .status_sql

    update_column_in_batches(:ci_stages, :status, Arel.sql("(#{status_sql})"))
  end

  def down
    execute <<-SQL.strip_heredoc
      UPDATE ci_stages SET status = null
    SQL
  end
end
