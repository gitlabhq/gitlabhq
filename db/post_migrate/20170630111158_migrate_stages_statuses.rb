class MigrateStagesStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'

    scope :relevant, -> do
      where(status: %w[pending running success failed canceled skipped manual])
    end

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
        false, all_state_names - [:failed, :canceled, :manual])
    end

    def status_sql
      scope_relevant = relevant.exclude_ignored
      scope_warnings = relevant.failed_but_allowed

      builds = scope_relevant.select('count(*)').to_sql
      created = scope_relevant.created.select('count(*)').to_sql
      success = scope_relevant.success.select('count(*)').to_sql
      manual = scope_relevant.manual.select('count(*)').to_sql
      pending = scope_relevant.pending.select('count(*)').to_sql
      running = scope_relevant.running.select('count(*)').to_sql
      skipped = scope_relevant.skipped.select('count(*)').to_sql
      canceled = scope_relevant.canceled.select('count(*)').to_sql
      warnings = scope_warnings.select('count(*) > 0').to_sql

      "(CASE
        WHEN (#{builds})=(#{skipped}) AND (#{warnings}) THEN 'success'
        WHEN (#{builds})=(#{skipped}) THEN 'skipped'
        WHEN (#{builds})=(#{success}) THEN 'success'
        WHEN (#{builds})=(#{created}) THEN 'created'
        WHEN (#{builds})=(#{success})+(#{skipped}) THEN 'success'
        WHEN (#{builds})=(#{success})+(#{skipped})+(#{canceled}) THEN 'canceled'
        WHEN (#{builds})=(#{created})+(#{skipped})+(#{pending}) THEN 'pending'
        WHEN (#{running})+(#{pending})>0 THEN 'running'
        WHEN (#{manual})>0 THEN 'manual'
        WHEN (#{created})>0 THEN 'running'
        ELSE 'failed'
      END)"
    end
  end

  def up
    execute <<-SQL.strip_heredoc
    SQL
  end

  def down
    execute <<-SQL.strip_heredoc
      UPDATE ci_stages SET status = null
    SQL
  end

  private

end
