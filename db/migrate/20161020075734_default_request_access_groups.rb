class DefaultRequestAccessGroups < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def up
    change_column_default :namespaces, :request_access_enabled, false
  end

  def down
    change_column_default :namespaces, :request_access_enabled, true
  end
end
