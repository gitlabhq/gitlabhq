class RemoveNilTypeServices < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute <<-SQL
      DELETE FROM services WHERE type IS NULL OR type = '';
    SQL
  end

  def down
  end
end
