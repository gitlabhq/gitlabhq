class AddNameToBoards < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :boards, :name, :string, default: 'Development'
  end

  def down
    remove_column :boards, :name
  end
end
