class MigrateStageIdReferenceInBackground < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
  end

  def down
    # noop
  end
end
