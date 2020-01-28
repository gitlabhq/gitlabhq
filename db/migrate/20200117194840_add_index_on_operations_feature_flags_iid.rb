# frozen_string_literal: true

class AddIndexOnOperationsFeatureFlagsIid < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :operations_feature_flags, [:project_id, :iid], unique: true
  end

  def down
    remove_concurrent_index :operations_feature_flags, [:project_id, :iid]
  end
end
