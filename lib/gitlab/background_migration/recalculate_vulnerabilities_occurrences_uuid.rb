# frozen_string_literal: true

# rubocop: disable Style/Documentation
class Gitlab::BackgroundMigration::RecalculateVulnerabilitiesOccurrencesUuid # rubocop:disable Metrics/ClassLength
  # rubocop: disable Gitlab/NamespacedClass
  class VulnerabilitiesIdentifier < ActiveRecord::Base
    self.table_name = "vulnerability_identifiers"
    has_many :primary_findings, class_name: 'VulnerabilitiesFinding', inverse_of: :primary_identifier, foreign_key: 'primary_identifier_id'
  end

  class VulnerabilitiesFinding < ActiveRecord::Base
    include EachBatch
    include ShaAttribute

    self.table_name = "vulnerability_occurrences"

    has_many :signatures, foreign_key: 'finding_id', class_name: 'VulnerabilityFindingSignature', inverse_of: :finding
    belongs_to :primary_identifier, class_name: 'VulnerabilitiesIdentifier', inverse_of: :primary_findings, foreign_key: 'primary_identifier_id'

    REPORT_TYPES = {
      sast: 0,
      dependency_scanning: 1,
      container_scanning: 2,
      dast: 3,
      secret_detection: 4,
      coverage_fuzzing: 5,
      api_fuzzing: 6,
      cluster_image_scanning: 7,
      generic: 99
    }.with_indifferent_access.freeze
    enum report_type: REPORT_TYPES

    sha_attribute :fingerprint
    sha_attribute :location_fingerprint
  end

  class VulnerabilityFindingSignature < ActiveRecord::Base
    include ShaAttribute

    self.table_name = 'vulnerability_finding_signatures'
    belongs_to :finding, foreign_key: 'finding_id', inverse_of: :signatures, class_name: 'VulnerabilitiesFinding'

    sha_attribute :signature_sha
  end

  class VulnerabilitiesFindingPipeline < ActiveRecord::Base
    include EachBatch
    self.table_name = "vulnerability_occurrence_pipelines"
  end

  class Vulnerability < ActiveRecord::Base
    include EachBatch
    self.table_name = "vulnerabilities"
  end

  class CalculateFindingUUID
    FINDING_NAMESPACES_IDS = {
      development: "a143e9e2-41b3-47bc-9a19-081d089229f4",
      test: "a143e9e2-41b3-47bc-9a19-081d089229f4",
      staging: "a6930898-a1b2-4365-ab18-12aa474d9b26",
      production: "58dc0f06-936c-43b3-93bb-71693f1b6570"
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

  # rubocop: disable Metrics/AbcSize,Metrics/MethodLength,Metrics/BlockLength
  def perform(start_id, end_id)
    log_info('Migration started', start_id: start_id, end_id: end_id)

    VulnerabilitiesFinding
      .joins(:primary_identifier)
      .includes(:signatures)
      .select(:id, :report_type, :primary_identifier_id, :fingerprint, :location_fingerprint, :project_id, :created_at, :vulnerability_id, :uuid)
      .where(id: start_id..end_id)
      .each_batch(of: 50) do |relation|
      duplicates = find_duplicates(relation)
      remove_findings(ids: duplicates) if duplicates.present?

      to_update = relation.reject { |finding| duplicates.include?(finding.id) }

      begin
        known_uuids = Set.new
        to_be_deleted = []

        mappings = to_update.each_with_object({}) do |finding, hash|
          uuid = calculate_uuid_v5_for_finding(finding)

          if known_uuids.add?(uuid)
            hash[finding] = { uuid: uuid }
          else
            to_be_deleted << finding.id
          end
        end

        # It is technically still possible to have duplicate uuids
        # if the data integrity is broken somehow and the primary identifiers of
        # the findings are pointing to different projects with the same fingerprint values.
        if to_be_deleted.present?
          log_info('Conflicting UUIDs found within the batch', finding_ids: to_be_deleted)

          remove_findings(ids: to_be_deleted)
        end

        ::Gitlab::Database::BulkUpdate.execute(%i[uuid], mappings) if mappings.present?

        log_info('Recalculation is done', finding_ids: mappings.keys.pluck(:id))
      rescue ActiveRecord::RecordNotUnique => error
        log_info('RecordNotUnique error received')

        match_data = /\(uuid\)=\((?<uuid>\S{36})\)/.match(error.message)

        # This exception returns the **correct** UUIDv5 which probably comes from a later record
        # and it's the one we can drop in the easiest way before retrying the UPDATE query
        if match_data
          uuid = match_data[:uuid]
          log_info('Conflicting UUID found', uuid: uuid)

          id = VulnerabilitiesFinding.find_by(uuid: uuid)&.id
          remove_findings(ids: id) if id
          retry
        else
          log_error('Couldnt find conflicting uuid')

          Gitlab::ErrorTracking.track_and_raise_exception(error)
        end
      end
    end

    mark_job_as_succeeded(start_id, end_id)
  rescue StandardError => error
    log_error('An exception happened')

    Gitlab::ErrorTracking.track_and_raise_exception(error)
  end
  # rubocop: disable Metrics/AbcSize,Metrics/MethodLength,Metrics/BlockLength

  private

  def find_duplicates(relation)
    to_exclude = []
    relation.flat_map do |record|
      # Assuming we're scanning id 31 and the duplicate is id 40
      # first we'd process 31 and add 40 to the list of ids to remove
      # then we would process record 40 and add 31 to the list of removals
      # so we would drop both records
      to_exclude << record.id

      VulnerabilitiesFinding.where(
        report_type: record.report_type,
        location_fingerprint: record.location_fingerprint,
        primary_identifier_id: record.primary_identifier_id,
        project_id: record.project_id
      ).where.not(id: to_exclude).pluck(:id)
    end
  end

  def remove_findings(ids:)
    ids = Array(ids)
    log_info('Removing Findings and associated records', ids: ids)

    vulnerability_ids = VulnerabilitiesFinding.where(id: ids).pluck(:vulnerability_id).uniq.compact

    VulnerabilitiesFindingPipeline.where(occurrence_id: ids).each_batch { |batch| batch.delete_all }
    Vulnerability.where(id: vulnerability_ids).each_batch { |batch| batch.delete_all }
    VulnerabilitiesFinding.where(id: ids).delete_all
  end

  def calculate_uuid_v5_for_finding(vulnerability_finding)
    return unless vulnerability_finding

    signatures = vulnerability_finding.signatures.sort_by { |signature| signature.algorithm_type_before_type_cast }
    location_fingerprint = signatures.last&.signature_sha || vulnerability_finding.location_fingerprint

    uuid_v5_name_components = {
      report_type: vulnerability_finding.report_type,
      primary_identifier_fingerprint: vulnerability_finding.fingerprint,
      location_fingerprint: location_fingerprint,
      project_id: vulnerability_finding.project_id
    }

    name = uuid_v5_name_components.values.join('-')

    CalculateFindingUUID.call(name)
  end

  def log_info(message, **extra)
    logger.info(migrator: 'RecalculateVulnerabilitiesOccurrencesUuid', message: message, **extra)
  end

  def log_error(message, **extra)
    logger.error(migrator: 'RecalculateVulnerabilitiesOccurrencesUuid', message: message, **extra)
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
