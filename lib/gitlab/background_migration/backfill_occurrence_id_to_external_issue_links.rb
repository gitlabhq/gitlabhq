# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Migration/BatchedMigrationBaseClass -- BackfillOccurrenceIdToVulnerabilityAssociations is a subclass
    # of BatchedMigrationJob
    class BackfillOccurrenceIdToExternalIssueLinks < BackfillOccurrenceIdToVulnerabilityAssociations
      # rubocop:enable Migration/BatchedMigrationBaseClass
      operation_name :backfill_occurrence_id_to_vulnerability_external_issue_links
    end
  end
end
