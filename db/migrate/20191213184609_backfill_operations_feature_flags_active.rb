# frozen_string_literal: true

class BackfillOperationsFeatureFlagsActive < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  disable_ddl_transaction!

  class OperationsFeatureFlag < ActiveRecord::Base
    self.table_name = 'operations_feature_flags'
    self.inheritance_column = :_type_disabled
  end

  def up
    OperationsFeatureFlag.where(active: false).update_all(active: true)
  end

  def down
    # no-op
  end
end
