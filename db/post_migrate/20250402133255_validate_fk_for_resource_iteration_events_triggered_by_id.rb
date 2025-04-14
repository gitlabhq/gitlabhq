# frozen_string_literal: true

class ValidateFkForResourceIterationEventsTriggeredById < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  TABLE_NAME = :resource_iteration_events
  COLUMN = :triggered_by_id
  FK_NAME = :fk_7d9260dbfb

  def up
    validate_foreign_key(TABLE_NAME, COLUMN, name: FK_NAME)
  end

  def down
    # no-op
  end
end
