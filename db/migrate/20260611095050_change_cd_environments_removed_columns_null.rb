# frozen_string_literal: true

class ChangeCdEnvironmentsRemovedColumnsNull < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  # cluster_agent_id, platform_type and region are being removed (drop deferred
  # to a follow-up). Make the NOT NULL columns nullable here so the model can
  # stop populating them via ignore_column.
  def up
    change_column_null :cd_environments, :cluster_agent_id, true
    change_column_null :cd_environments, :platform_type, true
  end

  def down
    change_column_null :cd_environments, :platform_type, false
    change_column_null :cd_environments, :cluster_agent_id, false
  end
end
