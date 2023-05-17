# frozen_string_literal: true

# This migration will look for Vulnerabilities::Finding objects that would have a duplicate UUIDv5 if the UUID was
# recalculated. Then it removes Vulnerabilities::FindingPipeline objects associated with those Findings.
# We can't just drop those Findings directly since the cascade drop will timeout if any given Finding has too many
# associated FindingPipelines
class Gitlab::BackgroundMigration::RemoveOccurrencePipelinesAndDuplicateVulnerabilitiesFindings
  # rubocop:disable Gitlab/NamespacedClass, Style/Documentation
  class VulnerabilitiesFinding < ActiveRecord::Base
    self.table_name = "vulnerability_occurrences"
  end

  class VulnerabilitiesFindingPipeline < ActiveRecord::Base
    include EachBatch
    self.table_name = "vulnerability_occurrence_pipelines"
  end
  # rubocop:enable Gitlab/NamespacedClass, Style/Documentation

  def perform(start_id, end_id)
    ids_to_look_for = findings_that_would_produce_duplicate_uuids(start_id, end_id)

    ids_to_look_for.each do |finding_id|
      VulnerabilitiesFindingPipeline.where(occurrence_id: finding_id).each_batch(of: 1000) do |pipelines|
        pipelines.delete_all
      end
    end

    VulnerabilitiesFinding.where(id: ids_to_look_for).delete_all

    mark_job_as_succeeded(start_id, end_id)
  end

  private

  def findings_that_would_produce_duplicate_uuids(start_id, end_id)
    VulnerabilitiesFinding
      .from("vulnerability_occurrences to_delete")
      .where("to_delete.id BETWEEN ? AND ?", start_id, end_id)
      .where(
        "EXISTS (
          SELECT 1
          FROM vulnerability_occurrences duplicates
          WHERE duplicates.report_type = to_delete.report_type
          AND duplicates.location_fingerprint = to_delete.location_fingerprint
          AND duplicates.primary_identifier_id = to_delete.primary_identifier_id
          AND duplicates.project_id = to_delete.project_id
          AND duplicates.id > to_delete.id
        )"
      )
      .pluck("to_delete.id")
  end

  def mark_job_as_succeeded(*arguments)
    Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
      self.class.name.demodulize,
      arguments
    )
  end
end
