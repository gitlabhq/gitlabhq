class AddIndexToLabelsForTitleAndProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :labels, :title
    add_concurrent_index :labels, :project_id
  end
end
