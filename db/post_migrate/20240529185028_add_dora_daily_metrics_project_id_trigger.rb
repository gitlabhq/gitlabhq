# frozen_string_literal: true

class AddDoraDailyMetricsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :dora_daily_metrics,
      sharding_key: :project_id,
      parent_table: :environments,
      parent_sharding_key: :project_id,
      foreign_key: :environment_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :dora_daily_metrics,
      sharding_key: :project_id,
      parent_table: :environments,
      parent_sharding_key: :project_id,
      foreign_key: :environment_id
    )
  end
end
