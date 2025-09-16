# frozen_string_literal: true

class CreateWorkItemAwardEmojiAggregationMv < ClickHouse::Migration
  def up
    execute <<-SQL
    CREATE MATERIALIZED VIEW IF NOT EXISTS work_item_award_emoji_aggregations_mv
    TO work_item_award_emoji_aggregations AS
      WITH work_item_ids AS (
        SELECT work_item_id FROM work_item_award_emoji_trigger
      ),
      aggregation AS (
          SELECT
              work_item_id,
              mapFromArrays(
                  CAST(groupArray(name) AS Array(LowCardinality(String))),
                  groupArray(toUInt32(count))
              ) AS counts_by_emoji,
              mapFromArrays(
                  CAST(groupArray(name) AS Array(LowCardinality(String))),
                  CAST(
                      groupArray(concat('/', arrayStringConcat(user_ids, '/'), '/')) AS Array(String)
                  )
              ) AS user_ids_by_emoji,
              false AS deleted,
              NOW() AS version
          FROM
              (
                  SELECT
                      work_item_id,
                      name,
                      count(distinct user_id) AS count,
                      arraySort(groupUniqArray(user_id)) AS user_ids
                  FROM
                      (
                          SELECT
                              work_item_id,
                              id,
                              argMax(name, version) as name,
                              argMax(user_id, version) as user_id,
                              argMax(deleted, version) as deleted
                          FROM
                              work_item_award_emoji
                          WHERE
                              work_item_id IN (select work_item_id from work_item_ids)
                          GROUP BY
                              work_item_id,
                              id
                      ) work_item_award_emoji
                  WHERE
                      deleted = false
                  GROUP BY
                      work_item_id,
                      name
              )
          GROUP BY
              work_item_id
      )
      SELECT
          work_item_ids.work_item_id AS work_item_id,
          aggregation.counts_by_emoji AS counts_by_emoji,
          aggregation.user_ids_by_emoji AS user_ids_by_emoji
      FROM
          work_item_ids
          LEFT JOIN aggregation ON aggregation.work_item_id = work_item_ids.work_item_id
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS work_item_award_emoji_aggregations_mv'
  end
end
