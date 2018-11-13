class ChangeTargetIdToNullOnTodos < ActiveRecord::Migration[4.2]
  def change
    change_column_null :todos, :target_id, true
  end
end
