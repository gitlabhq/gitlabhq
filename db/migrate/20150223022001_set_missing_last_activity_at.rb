class SetMissingLastActivityAt < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE projects SET last_activity_at = updated_at WHERE last_activity_at IS NULL"
  end

  def down
  end
end
