class RemoveRedundantPipelineStages < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up(attempts: 100)
    remove_redundant_pipeline_stages!
    remove_outdated_index!
    add_unique_index!
  rescue ActiveRecord::RecordNotUnique
    retry if (attempts -= 1) > 0

    raise StandardError, <<~EOS
      Failed to add an unique index to ci_stages, despite retrying the
      migration 100 times.

      See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/16580.
    EOS
  end

  def down
    remove_concurrent_index :ci_stages, [:pipeline_id, :name], unique: true
    add_concurrent_index :ci_stages, [:pipeline_id, :name]
  end

  private

  def remove_outdated_index!
    return unless index_exists?(:ci_stages, [:pipeline_id, :name])

    remove_concurrent_index :ci_stages, [:pipeline_id, :name]
  end

  def add_unique_index!
    add_concurrent_index :ci_stages, [:pipeline_id, :name], unique: true
  end

  def remove_redundant_pipeline_stages!
    disable_statement_timeout do
      redundant_stages_ids = <<~SQL
        SELECT id FROM ci_stages WHERE (pipeline_id, name) IN (
          SELECT pipeline_id, name FROM ci_stages
            GROUP BY pipeline_id, name HAVING COUNT(*) > 1
        )
      SQL

      execute <<~SQL
        UPDATE ci_builds SET stage_id = NULL WHERE stage_id IN (#{redundant_stages_ids})
      SQL

      execute <<~SQL
        DELETE FROM ci_stages WHERE id IN (#{redundant_stages_ids})
      SQL
    end
  end
end
