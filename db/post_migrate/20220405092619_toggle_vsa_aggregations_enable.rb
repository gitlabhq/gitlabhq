# frozen_string_literal: true

class ToggleVsaAggregationsEnable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    model = define_batchable_model('analytics_cycle_analytics_aggregations')

    model.each_batch(of: 100) do |relation|
      relation.where('enabled IS FALSE').update_all(enabled: true)
    end
  end

  def down
    # noop
  end
end
