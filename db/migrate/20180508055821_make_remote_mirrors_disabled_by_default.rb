class MakeRemoteMirrorsDisabledByDefault < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    change_column_default :remote_mirrors, :enabled, false
  end

  def down
    change_column_default :remote_mirrors, :enabled, true
  end
end
