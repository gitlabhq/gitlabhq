module Gitlab
  module BackgroundMigration
    class MigrateBuildStageIdReference
      def perform(id)
        raise ArgumentError unless id.present?

        sql = <<-SQL.strip_heredoc
          UPDATE "ci_builds" SET "stage_id" = (
            SELECT id FROM ci_stages
              WHERE ci_stages.pipeline_id = ci_builds.commit_id
              AND ci_stages.name = ci_builds.stage
            )
          WHERE "ci_builds"."id" = #{id} AND "ci_builds"."stage_id" IS NULL
        SQL

        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end
end
