class MigrateTriggerSchedulesToPipelineSchedules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    connection.execute <<-SQL
      INSERT INTO ci_pipeline_schedules (
        project_id,
        created_at,
        updated_at,
        deleted_at,
        cron,
        cron_timezone,
        next_run_at,
        ref,
        active,
        owner_id,
        description
      )
      SELECT
        ci_trigger_schedules.project_id,
        ci_trigger_schedules.created_at,
        ci_trigger_schedules.updated_at,
        ci_trigger_schedules.deleted_at,
        ci_trigger_schedules.cron,
        ci_trigger_schedules.cron_timezone,
        ci_trigger_schedules.next_run_at,
        ci_trigger_schedules.ref,
        ci_trigger_schedules.active,
        ci_triggers.owner_id,
        ci_triggers.description
      FROM ci_trigger_schedules
      LEFT JOIN ci_triggers ON ci_trigger_schedules.trigger_id=ci_triggers.id;
    SQL

    # Using the foreign key, this removes the trigger schedules also.
    # The nesting of the queries makes MySQL ok with this query, it used to
    # throw a `ERROR 1093 (HY000): You can't specify target table 'ci_triggers' for update in FROM clause`
    connection.execute <<-SQL
      DELETE FROM ci_triggers
      WHERE id IN (
        SELECT trigger_id FROM (
          SELECT ci_triggers.id AS trigger_id FROM ci_triggers
          LEFT JOIN ci_trigger_schedules ON ci_triggers.id = ci_trigger_schedules.trigger_id
        ) AS tid
      );
    SQL
  end

  def down
    # no op as the data has been removed
  end
end
