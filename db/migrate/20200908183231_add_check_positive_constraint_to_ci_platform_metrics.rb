# frozen_string_literal: true

class AddCheckPositiveConstraintToCiPlatformMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'ci_platform_metrics_check_count_positive'

  def up
    add_check_constraint :ci_platform_metrics, 'count > 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :ci_platform_metrics, CONSTRAINT_NAME
  end
end
