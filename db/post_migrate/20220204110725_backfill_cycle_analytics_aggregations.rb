# frozen_string_literal: true

class BackfillCycleAnalyticsAggregations < Gitlab::Database::Migration[1.0]
  BATCH_SIZE = 50

  def up
    model = define_batchable_model('analytics_cycle_analytics_group_value_streams')

    model.each_batch(of: BATCH_SIZE) do |relation|
      execute <<~SQL
      WITH records_to_be_inserted AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
        SELECT root_ancestor.id AS group_id
        FROM (#{relation.select(:group_id).to_sql}) as value_streams,
        LATERAL (
          WITH RECURSIVE "base_and_ancestors" AS (
            (SELECT "namespaces"."id", "namespaces"."parent_id"  FROM "namespaces" WHERE "namespaces"."id" = value_streams.group_id)
          UNION
            (SELECT "namespaces"."id", "namespaces"."parent_id" FROM "namespaces", "base_and_ancestors" WHERE "namespaces"."id" = "base_and_ancestors"."parent_id")
          )
          SELECT "namespaces"."id" FROM "base_and_ancestors" as "namespaces" WHERE parent_id IS NULL LIMIT 1
        ) as root_ancestor
      )
      INSERT INTO "analytics_cycle_analytics_aggregations"
      SELECT * FROM "records_to_be_inserted"
      ON CONFLICT DO NOTHING
      SQL
    end
  end

  def down
    # no-op
  end
end
