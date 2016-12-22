class RemoveUnneededServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute("DELETE FROM services WHERE active = false AND properties = '{}';")
  end

  def down
    # noop
  end
end
