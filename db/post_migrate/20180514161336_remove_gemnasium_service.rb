class RemoveGemnasiumService < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    disable_statement_timeout

    execute("DELETE FROM services WHERE type='GemnasiumService';")
  end

  def down
    # noop
  end
end
