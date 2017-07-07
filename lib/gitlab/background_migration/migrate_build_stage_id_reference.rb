module Gitlab
  module BackgroundMigration
    class MigrateBuildStageIdReference
      def perform(start_id, stop_id)
        scope = if stop_id.to_i.nonzero?
                  "ci_builds.id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}"
                else
                  "ci_builds.id >= #{start_id.to_i}"
                end

        sql = <<-SQL.strip_heredoc
          UPDATE "ci_builds"
            SET "stage_id" =
              (SELECT id FROM ci_stages
                WHERE ci_stages.pipeline_id = ci_builds.commit_id
                AND ci_stages.name = ci_builds.stage)
          WHERE #{scope} AND "ci_builds"."stage_id" IS NULL
        SQL

        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end
end
