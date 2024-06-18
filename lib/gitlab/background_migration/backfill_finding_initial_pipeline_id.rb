# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This batched background migration is EE-only, see
    # ee/lib/ee/gitlab/background_migration/backfill_finding_initial_pipeline_id.rb
    # for the actual migration code.
    #
    # This batched background migration will backfill the
    # `initial_pipeline_id` field in `vulnerability_occurrences` table
    # for records with `initial_pipeline_id: nil`
    class BackfillFindingInitialPipelineId < BatchedMigrationJob
      feature_category :vulnerability_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillFindingInitialPipelineId.prepend_mod
