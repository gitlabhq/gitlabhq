# frozen_string_literal: true

class AddCiPipelineSchedulesToPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:plan_limits, :ci_pipeline_schedules, :integer, default: 0, allow_null: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:plan_limits, :ci_pipeline_schedules)
  end
end
