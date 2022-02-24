# frozen_string_literal: true

class AddTextLimitToEpicsColor < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :epics, :color, 7
  end

  def down
    remove_text_limit :epics, :color
  end
end
