class RemoveRedundantPipelineStages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
   redundant_stages_ids = <<~SQL
      SELECT id FROM ci_stages a WHERE (
        SELECT COUNT(*) FROM ci_stages b
          WHERE a.pipeline_id = b.pipeline_id AND a.name = b.name
      ) > 1
    SQL

    execute <<~SQL
      UPDATE ci_builds SET stage_id = NULL WHERE ci_builds.stage_id IN (#{redundant_stages_ids})
    SQL

    execute <<~SQL
      DELETE FROM ci_stages WHERE ci_stages.id IN (#{redundant_stages_ids})
    SQL
  end

  def down
    # noop
  end
end
