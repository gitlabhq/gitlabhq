class RemoveRedundantPipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    redundant_stages_ids = <<~SQL
      SELECT id FROM ci_stages WHERE (pipeline_id, name) IN (
        SELECT pipeline_id, name FROM ci_stages
          GROUP BY pipeline_id, name HAVING COUNT(*) > 1
      )
    SQL

    execute <<~SQL
      UPDATE ci_builds SET stage_id = NULL WHERE stage_id IN (#{redundant_stages_ids})
    SQL

    if Gitlab::Database.postgresql?
      execute <<~SQL
        DELETE FROM ci_stages WHERE id IN (#{redundant_stages_ids})
      SQL
    else # We can't modify a table we are selecting from on MySQL
      execute <<~SQL
        DELETE a FROM ci_stages AS a, ci_stages AS b
          WHERE a.pipeline_id = b.pipeline_id AND a.name = b.name
            AND a.id <> b.id
      SQL
    end
  end

  def down
    # noop
  end
end
