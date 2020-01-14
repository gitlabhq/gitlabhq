# frozen_string_literal: true

class DeleteLegacyTriggers < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    execute <<~SQL
      DELETE FROM ci_triggers WHERE owner_id IS NULL
    SQL

    change_column_null :ci_triggers, :owner_id, false
  end

  def down
    change_column_null :ci_triggers, :owner_id, true
  end
end
