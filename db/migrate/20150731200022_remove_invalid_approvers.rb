class RemoveInvalidApprovers < ActiveRecord::Migration
  def up
    execute("DELETE FROM approvers WHERE user_id = 0")
  end

  def down
  end
end
