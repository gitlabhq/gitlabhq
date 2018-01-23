class AddRemoteNameToRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :remote_mirrors, :remote_name, :string
  end
end
