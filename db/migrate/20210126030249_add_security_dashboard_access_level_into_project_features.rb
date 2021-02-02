# frozen_string_literal: true

class AddSecurityDashboardAccessLevelIntoProjectFeatures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  PRIVATE_ACCESS_LEVEL = 10

  def up
    with_lock_retries do
      add_column :project_features, :security_and_compliance_access_level, :integer, default: PRIVATE_ACCESS_LEVEL, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_features, :security_and_compliance_access_level
    end
  end
end
