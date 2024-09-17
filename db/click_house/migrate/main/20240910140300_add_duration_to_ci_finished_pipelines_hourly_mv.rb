# frozen_string_literal: true

class AddDurationToCiFinishedPipelinesHourlyMv < ClickHouse::Migration
  def up
    execute <<~SQL
     ALTER TABLE ci_finished_pipelines_hourly_mv
       MODIFY QUERY
       SELECT
           path,
           status,
           source,
           ref,
           toStartOfInterval(started_at, INTERVAL 1 hour) AS started_at_bucket,

           countState() AS count_pipelines,
           quantileState(duration) AS duration_quantile
       FROM ci_finished_pipelines
       GROUP BY path, status, source, ref, started_at_bucket
    SQL
  end

  def down
    execute <<~SQL
     ALTER TABLE ci_finished_pipelines_hourly_mv
       MODIFY QUERY
       SELECT
         path,
         status,
         source,
         ref,
         toStartOfInterval(started_at, INTERVAL 1 hour) AS started_at_bucket,

         countState() AS count_pipelines
       FROM ci_finished_pipelines
       GROUP BY path, status, source, ref, started_at_bucket
    SQL
  end
end
