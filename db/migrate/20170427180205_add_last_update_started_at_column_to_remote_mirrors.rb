# rubocop:disable Migration/Datetime
class AddLastUpdateStartedAtColumnToRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :remote_mirrors, :last_update_started_at, :datetime
  end
end
