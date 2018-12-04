# rubocop:disable Migration/UpdateLargeTable
class AddRequestAccessEnabledToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default :projects, :request_access_enabled, :boolean, default: true
  end

  def down
    remove_column :projects, :request_access_enabled
  end
end
