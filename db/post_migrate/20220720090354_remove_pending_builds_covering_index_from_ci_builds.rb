# frozen_string_literal: true

class RemovePendingBuildsCoveringIndexFromCiBuilds < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_builds_runner_id_pending_covering'

  def up
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end

  # rubocop:disable Migration/PreventIndexCreation
  def down
    disable_statement_timeout do
      unless index_exists_by_name?(:ci_builds, INDEX_NAME)
        execute <<~SQL.squish
          CREATE INDEX CONCURRENTLY #{INDEX_NAME}
            ON ci_builds (runner_id, id)
            INCLUDE (project_id)
            WHERE status = 'pending' AND type = 'Ci::Build'
        SQL
      end
    end
  end
  # rubocop:enable Migration/PreventIndexCreation
end
