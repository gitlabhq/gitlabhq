# frozen_string_literal: true

class AddIidToOperationsFeatureFlags < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :operations_feature_flags, :iid, :integer
  end

  def down
    remove_column :operations_feature_flags, :iid
  end
end
