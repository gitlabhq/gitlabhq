# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGeoNodeCloneProtocol < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :geo_nodes, :clone_protocol, :string, allow_null: false, default: 'ssh'
    change_column_default :geo_nodes, :clone_protocol, 'http'
  end

  def down
    remove_column :geo_nodes, :clone_protocol
  end
end
