# frozen_string_literal: true

class AddEpicsRelativePosition < Gitlab::Database::Migration[1.0]
  DOWNTIME = false

  def up
    return unless table_exists?(:epics)
    return if column_exists?(:epics, :relative_position)

    add_column :epics, :relative_position, :integer

    execute('UPDATE epics SET relative_position=id*500')
  end

  def down
    # no-op - this column should normally exist if epics table exists too
  end
end
