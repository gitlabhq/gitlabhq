class AddRemoteNameToRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # When moving from CE to EE, this column may already exist
    return if column_exists?(:remote_mirrors, :remote_name)

    add_column :remote_mirrors, :remote_name, :string
  end

  def down
    remove_column :remote_mirrors, :remote_name
  end
end
