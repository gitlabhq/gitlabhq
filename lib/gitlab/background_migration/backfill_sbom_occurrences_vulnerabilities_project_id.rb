# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSbomOccurrencesVulnerabilitiesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_sbom_occurrences_vulnerabilities_project_id
      feature_category :dependency_management

      def perform
        ::Gitlab::Database.allow_cross_joins_across_databases(
          url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/477860'
        ) do
          each_sub_batch do |sub_batch|
            sub_batch.connection.execute(construct_query(sub_batch: sub_batch))
          end
        end
      end
    end
  end
end
