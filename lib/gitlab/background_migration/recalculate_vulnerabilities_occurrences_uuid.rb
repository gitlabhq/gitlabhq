# frozen_string_literal: true

# rubocop: disable Style/Documentation
class Gitlab::BackgroundMigration::RecalculateVulnerabilitiesOccurrencesUuid
  # rubocop: disable Gitlab/NamespacedClass
  class VulnerabilitiesIdentifier < ActiveRecord::Base
    self.table_name = "vulnerability_identifiers"
    has_many :primary_findings, class_name: 'VulnerabilitiesFinding', inverse_of: :primary_identifier, foreign_key: 'primary_identifier_id'
  end

  class VulnerabilitiesFinding < ActiveRecord::Base
    self.table_name = "vulnerability_occurrences"
    belongs_to :primary_identifier, class_name: 'VulnerabilitiesIdentifier', inverse_of: :primary_findings, foreign_key: 'primary_identifier_id'
    REPORT_TYPES = {
      sast: 0,
      dependency_scanning: 1,
      container_scanning: 2,
      dast: 3,
      secret_detection: 4,
      coverage_fuzzing: 5,
      api_fuzzing: 6
    }.with_indifferent_access.freeze
    enum report_type: REPORT_TYPES
  end

  class CalculateFindingUUID
    FINDING_NAMESPACES_IDS = {
      development: "a143e9e2-41b3-47bc-9a19-081d089229f4",
      test: "a143e9e2-41b3-47bc-9a19-081d089229f4",
      staging: "a6930898-a1b2-4365-ab18-12aa474d9b26",
      production:  "58dc0f06-936c-43b3-93bb-71693f1b6570"
    }.freeze

    NAMESPACE_REGEX = /(\h{8})-(\h{4})-(\h{4})-(\h{4})-(\h{4})(\h{8})/.freeze
    PACK_PATTERN = "NnnnnN"

    def self.call(value)
      Digest::UUID.uuid_v5(namespace_id, value)
    end

    def self.namespace_id
      namespace_uuid = FINDING_NAMESPACES_IDS.fetch(Rails.env.to_sym)
      # Digest::UUID is broken when using an UUID in namespace_id
      # https://github.com/rails/rails/issues/37681#issue-520718028
      namespace_uuid.scan(NAMESPACE_REGEX).flatten.map { |s| s.to_i(16) }.pack(PACK_PATTERN)
    end
  end
  # rubocop: enable Gitlab/NamespacedClass

  def perform(start_id, end_id)
    findings = VulnerabilitiesFinding
      .joins(:primary_identifier)
      .select(:id, :report_type, :fingerprint, :location_fingerprint, :project_id)
      .where(id: start_id..end_id)

    mappings = findings.each_with_object({}) do |finding, hash|
      hash[finding] = { uuid: calculate_uuid_v5_for_finding(finding) }
    end

    ::Gitlab::Database::BulkUpdate.execute(%i[uuid], mappings)

    logger.info(message: 'RecalculateVulnerabilitiesOccurrencesUuid Migration: recalculation is done for:',
              finding_ids: mappings.keys.pluck(:id))

    mark_job_as_succeeded(start_id, end_id)
  rescue StandardError => error
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
  end

  private

  def calculate_uuid_v5_for_finding(vulnerability_finding)
    return unless vulnerability_finding

    uuid_v5_name_components = {
      report_type: vulnerability_finding.report_type,
      primary_identifier_fingerprint: vulnerability_finding.fingerprint,
      location_fingerprint: vulnerability_finding.location_fingerprint,
      project_id: vulnerability_finding.project_id
    }

    name = uuid_v5_name_components.values.join('-')

    CalculateFindingUUID.call(name)
  end

  def logger
    @logger ||= Gitlab::BackgroundMigration::Logger.build
  end

  def mark_job_as_succeeded(*arguments)
    Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
      'RecalculateVulnerabilitiesOccurrencesUuid',
      arguments
    )
  end
end
