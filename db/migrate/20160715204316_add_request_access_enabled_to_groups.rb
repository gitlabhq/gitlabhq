# rubocop:disable Migration/UpdateLargeTable
class AddRequestAccessEnabledToGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default :namespaces, :request_access_enabled, :boolean, default: true
  end

  def down
    remove_column :namespaces, :request_access_enabled
  end
end
