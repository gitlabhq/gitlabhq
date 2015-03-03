class SetMissingLastActivityAt < ActiveRecord::Migration
  def up
    execute "UPDATE projects SET last_activity_at = updated_at WHERE last_activity_at IS NULL"
  end

  def down
  end
end
