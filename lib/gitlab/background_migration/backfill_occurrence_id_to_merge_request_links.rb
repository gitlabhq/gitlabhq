# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Migration/BatchedMigrationBaseClass -- BackfillOccurrenceIdToVulnerabilityAssociations is a subclass
    # of BatchedMigrationJob
    class BackfillOccurrenceIdToMergeRequestLinks < BackfillOccurrenceIdToVulnerabilityAssociations
      # rubocop:enable Migration/BatchedMigrationBaseClass
      operation_name :backfill_occurrence_id_to_vulnerability_merge_request_links
    end
  end
end
