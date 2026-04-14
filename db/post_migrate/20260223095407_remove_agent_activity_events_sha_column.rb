# frozen_string_literal: true

class RemoveAgentActivityEventsShaColumn < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  TABLE_NAME = :agent_activity_events
  COLUMN_NAME = :sha

  def up
    remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
  end

  def down
    add_column TABLE_NAME, COLUMN_NAME, :binary, if_not_exists: true
  end
end
