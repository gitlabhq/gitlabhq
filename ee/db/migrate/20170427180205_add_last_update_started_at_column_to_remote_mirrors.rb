# rubocop:disable Migration/Datetime
class AddLastUpdateStartedAtColumnToRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # When moving from CE to EE, this column may already exist
    return if column_exists?(:remote_mirrors, :last_update_started_at)

    add_column :remote_mirrors, :last_update_started_at, :datetime
  end

  def down
    remove_column :remote_mirrors, :last_update_started_at
  end
end
