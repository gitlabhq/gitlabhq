# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSecurityFindingsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_security_findings_project_id
      feature_category :vulnerability_management

      scope_to ->(relation) { relation }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.connection.execute(construct_query(sub_batch: sub_batch.where(backfill_column => nil)))
        end
      end
    end
  end
end
