# frozen_string_literal: true

class SchedulePopulatePersonalSnippetStatistics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 500
  MIGRATION = 'PopulatePersonalSnippetStatistics'

  disable_ddl_transaction!

  def up
    snippets = exec_query <<~SQL
      SELECT id
      FROM snippets
      WHERE type = 'PersonalSnippet'
      ORDER BY author_id ASC, id ASC
    SQL

    snippets.rows.flatten.in_groups_of(BATCH_SIZE, false).each_with_index do |snippet_ids, index|
      migrate_in(index * DELAY_INTERVAL, MIGRATION, [snippet_ids])
    end
  end

  def down
    # no-op
  end
end
