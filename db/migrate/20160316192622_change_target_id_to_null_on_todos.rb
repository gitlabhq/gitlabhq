class ChangeTargetIdToNullOnTodos < ActiveRecord::Migration
  def change
    change_column_null :todos, :target_id, true
  end
end
