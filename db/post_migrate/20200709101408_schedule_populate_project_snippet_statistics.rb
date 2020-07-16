# frozen_string_literal: true

class SchedulePopulateProjectSnippetStatistics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION = 'PopulateProjectSnippetStatistics'

  disable_ddl_transaction!

  def up
    snippets = exec_query <<~SQL
      SELECT snippets.id
      FROM snippets
      INNER JOIN projects ON projects.id = snippets.project_id
      WHERE snippets.type = 'ProjectSnippet'
      ORDER BY projects.namespace_id ASC, snippets.project_id ASC, snippets.id ASC
    SQL

    snippets.rows.flatten.in_groups_of(BATCH_SIZE, false).each_with_index do |snippet_ids, index|
      migrate_in(index * DELAY_INTERVAL, MIGRATION, [snippet_ids])
    end
  end

  def down
    # no-op
  end
end
