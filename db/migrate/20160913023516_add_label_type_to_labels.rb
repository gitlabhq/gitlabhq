class AddLabelTypeToLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :labels, :label_type, :integer, default: 2
  end

  def down
    remove_column :labels, :label_type
  end
end
