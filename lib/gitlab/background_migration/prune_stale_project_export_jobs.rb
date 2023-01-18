# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for deleting stale project import jobs
    class PruneStaleProjectExportJobs < BatchedMigrationJob
      EXPIRES_IN = 7.days

      scope_to ->(relation) { relation.where("updated_at < ?", EXPIRES_IN.ago) }
      operation_name :delete_all
      feature_category :database

      def perform
        each_sub_batch(&:delete_all)
      end
    end
  end
end
