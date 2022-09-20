# frozen_string_literal: true

class DropIndexCadenceCreateIterationsAutomation < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'cadence_create_iterations_automation'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :iterations_cadences, INDEX_NAME
  end

  def down
    execute(
      <<-SQL
        CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON iterations_cadences
        USING BTREE(automatic, duration_in_weeks, (DATE ((COALESCE("iterations_cadences"."last_run_date", DATE('01-01-1970')) + "iterations_cadences"."duration_in_weeks" * INTERVAL '1 week')))) 
        WHERE duration_in_weeks IS NOT NULL
      SQL
    )
  end
end
