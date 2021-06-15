# frozen_string_literal: true

class RebuildIndexForCadenceIterationsAutomation < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'cadence_create_iterations_automation'

  disable_ddl_transaction!

  def up
    return if index_exists_and_is_valid?

    remove_concurrent_index_by_name :iterations_cadences, INDEX_NAME

    disable_statement_timeout do
      execute(
        <<-SQL
          CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON iterations_cadences
          USING BTREE(automatic, duration_in_weeks, (DATE ((COALESCE("iterations_cadences"."last_run_date", DATE('01-01-1970')) + "iterations_cadences"."duration_in_weeks" * INTERVAL '1 week')))) 
          WHERE duration_in_weeks IS NOT NULL
      SQL
      )
    end
  end

  def down
    remove_concurrent_index_by_name :iterations_cadences, INDEX_NAME
  end

  def index_exists_and_is_valid?
    execute(
      <<-SQL
        SELECT identifier
        FROM postgres_indexes
        WHERE identifier LIKE '%#{INDEX_NAME}' AND valid_index=TRUE
      SQL
    ).any?
  end
end
