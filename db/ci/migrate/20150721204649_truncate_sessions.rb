class TruncateSessions < ActiveRecord::Migration
  def up
    execute('DELETE FROM sessions')
  end

  def down
    execute('DELETE FROM sessions')
  end
end
