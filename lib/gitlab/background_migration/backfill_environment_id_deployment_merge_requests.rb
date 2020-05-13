# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # BackfillEnvironmentIdDeploymentMergeRequests deletes duplicates
    # from deployment_merge_requests table and backfills environment_id
    class BackfillEnvironmentIdDeploymentMergeRequests
      def perform(_start_mr_id, _stop_mr_id)
        # no-op

        # Background migration removed due to
        # https://gitlab.com/gitlab-org/gitlab/-/issues/217191
      end

      def backfill_range(start_mr_id, stop_mr_id)
        start_mr_id = Integer(start_mr_id)
        stop_mr_id  = Integer(stop_mr_id)

        ActiveRecord::Base.connection.execute(<<~SQL)
        DELETE FROM deployment_merge_requests
        WHERE (deployment_id, merge_request_id) in (
              SELECT t.deployment_id, t.merge_request_id  FROM (
                     SELECT mrd.merge_request_id, mrd.deployment_id, ROW_NUMBER() OVER w AS rnum
                     FROM deployment_merge_requests as mrd
                          INNER JOIN "deployments" ON "deployments"."id" = "mrd"."deployment_id"
                     WHERE mrd.merge_request_id BETWEEN #{start_mr_id} AND #{stop_mr_id}
                     WINDOW w AS (
                            PARTITION BY merge_request_id, deployments.environment_id
                            ORDER BY deployments.id
                     )
              ) t
              WHERE t.rnum > 1
        );
        SQL

        ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE deployment_merge_requests
        SET environment_id = deployments.environment_id
        FROM deployments
        WHERE deployments.id = "deployment_merge_requests".deployment_id
              AND "deployment_merge_requests".environment_id IS NULL
              AND "deployment_merge_requests".merge_request_id BETWEEN #{start_mr_id} AND #{stop_mr_id}
        SQL
      end
    end
  end
end
