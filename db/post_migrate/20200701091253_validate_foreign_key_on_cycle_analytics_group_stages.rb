# frozen_string_literal: true

class ValidateForeignKeyOnCycleAnalyticsGroupStages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  # same as in db/migrate/20200701064756_add_not_valid_foreign_key_to_cycle_analytics_group_stages.rb
  CONSTRAINT_NAME = 'fk_analytics_cycle_analytics_group_stages_group_value_stream_id'

  def up
    validate_foreign_key :analytics_cycle_analytics_group_stages, :group_value_stream_id, name: CONSTRAINT_NAME
  end

  def down
    remove_foreign_key_if_exists :analytics_cycle_analytics_group_stages, column: :group_value_stream_id, name: CONSTRAINT_NAME
    add_foreign_key :analytics_cycle_analytics_group_stages, :analytics_cycle_analytics_group_value_streams,
      column: :group_value_stream_id, name: CONSTRAINT_NAME, on_delete: :cascade, validate: false
  end
end
