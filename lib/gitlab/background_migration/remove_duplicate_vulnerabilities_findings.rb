# frozen_string_literal: true

# rubocop: disable Style/Documentation
class Gitlab::BackgroundMigration::RemoveDuplicateVulnerabilitiesFindings
  DELETE_BATCH_SIZE = 50

  # rubocop:disable Gitlab/NamespacedClass
  class VulnerabilitiesFinding < ActiveRecord::Base
    self.table_name = "vulnerability_occurrences"
  end
  # rubocop:enable Gitlab/NamespacedClass

  # rubocop:disable Gitlab/NamespacedClass
  class Vulnerability < ActiveRecord::Base
    self.table_name = "vulnerabilities"
  end
  # rubocop:enable Gitlab/NamespacedClass

  def perform(start_id, end_id)
    batch = VulnerabilitiesFinding.where(id: start_id..end_id)

    cte = Gitlab::SQL::CTE.new(:batch, batch.select(:report_type, :location_fingerprint, :primary_identifier_id, :project_id))

    query = VulnerabilitiesFinding
      .select('batch.report_type', 'batch.location_fingerprint', 'batch.primary_identifier_id', 'batch.project_id', 'array_agg(id) as ids')
      .distinct
      .with(cte.to_arel)
      .from(cte.alias_to(Arel.sql('batch')))
      .joins(
        %(
        INNER JOIN
        vulnerability_occurrences ON
        vulnerability_occurrences.report_type = batch.report_type AND
        vulnerability_occurrences.location_fingerprint = batch.location_fingerprint AND
        vulnerability_occurrences.primary_identifier_id = batch.primary_identifier_id AND
        vulnerability_occurrences.project_id = batch.project_id
      )).group('batch.report_type', 'batch.location_fingerprint', 'batch.primary_identifier_id', 'batch.project_id')
        .having('COUNT(*) > 1')

    ids_to_delete = []

    query.to_a.each do |record|
      # We want to keep the latest finding since it might have recent metadata
      duplicate_ids = record.ids.uniq.sort
      duplicate_ids.pop
      ids_to_delete.concat(duplicate_ids)

      if ids_to_delete.size == DELETE_BATCH_SIZE
        delete_findings_and_vulnerabilities(ids_to_delete)
        ids_to_delete.clear
      end
    end

    delete_findings_and_vulnerabilities(ids_to_delete) if ids_to_delete.any?
  end

  private

  def delete_findings_and_vulnerabilities(ids)
    vulnerability_ids = VulnerabilitiesFinding.where(id: ids).pluck(:vulnerability_id).compact
    VulnerabilitiesFinding.where(id: ids).delete_all
    Vulnerability.where(id: vulnerability_ids).delete_all
  end
end
