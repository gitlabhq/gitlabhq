# frozen_string_literal: true

module Vulnerabilities
  class Occurrence < ActiveRecord::Base
    include ShaAttribute
    include ::Gitlab::Utils::StrongMemoize

    self.table_name = "vulnerability_occurrences"

    # Used for both severity and confidence
    LEVELS = {
      undefined: 0,
      ignore: 1,
      unknown: 2,
      experimental: 3,
      low: 4,
      medium: 5,
      high: 6,
      critical: 7
    }.with_indifferent_access.freeze

    sha_attribute :project_fingerprint
    sha_attribute :primary_identifier_fingerprint
    sha_attribute :location_fingerprint

    belongs_to :project
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner'

    has_many :occurrence_identifiers, class_name: 'Vulnerabilities::OccurrenceIdentifier'
    has_many :identifiers, through: :occurrence_identifiers, class_name: 'Vulnerabilities::Identifier'

    REPORT_TYPES = {
      sast: 0,
      dependency_scanning: 1,
      container_scanning: 2,
      dast: 3
    }.with_indifferent_access.freeze

    enum report_type: REPORT_TYPES

    validates :scanner, presence: true
    validates :project, presence: true
    validates :pipeline, presence: true
    validates :uuid, presence: true
    validates :ref, presence: true

    validates :project_fingerprint, presence: true
    validates :primary_identifier_fingerprint, presence: true
    validates :location_fingerprint, presence: true
    # Uniqueness validation doesn't work with binary columns, so save this useless query. It is enforce by DB constraint anyway.
    # TODO: find out why it fails
    # validates :location_fingerprint, presence: true, uniqueness: { scope: [:primary_identifier_fingerprint, :scanner_id, :ref, :pipeline_id, :project_id] }
    validates :name, presence: true
    validates :report_type, presence: true
    validates :severity, presence: true, inclusion: { in: LEVELS.keys }
    validates :confidence, presence: true, inclusion: { in: LEVELS.keys }

    validates :metadata_version, presence: true
    validates :raw_metadata, presence: true

    scope :ordered, -> { order("severity desc", :id) }
    scope :counted_by_report_and_severity, -> { group(:report_type, :severity).count }

    def feedback(feedback_type:)
      params = {
        project_id: project_id,
        category: report_type,
        project_fingerprint: project_fingerprint,
        feedback_type: feedback_type
      }

      BatchLoader.for(params).batch do |items, loader|
        project_ids = items.group_by { |i| i[:project_id] }
        categories = items.group_by { |i| i[:category] }
        fingerprints = items.group_by { |i| i[:project_fingerprint] }

        VulnerabilityFeedback.where(
          project_id: project_ids.keys,
          category: categories.keys,
          project_fingerprint: fingerprints.keys).find_each do |feedback|
          loaded_params = {
            project_id: feedback.project_id,
            category: feedback.category,
            project_fingerprint: feedback.project_fingerprint,
            feedback_type: feedback.feedback_type
          }
          loader.call(loaded_params, feedback)
        end
      end
    end

    def dismissal_feedback
      feedback(feedback_type: 'dismissal')
    end

    def issue_feedback
      feedback(feedback_type: 'issue')
    end

    # Override getter and setter for :severity as we can't use enum (it conflicts with :confidence)
    # To be replaced with enum using _prefix when migrating to rails 5
    def severity
      LEVELS.key(read_attribute(:severity))
    end

    def severity=(severity)
      write_attribute(:severity, LEVELS[severity])
    end

    # Override getter and setter for :confidence as we can't use enum (it conflicts with :severity)
    # To be replaced with enum using _prefix when migrating to rails 5
    def confidence
      LEVELS.key(read_attribute(:confidence))
    end

    def confidence=(confidence)
      write_attribute(:confidence, LEVELS[confidence])
    end

    def metadata
      strong_memoize(:metadata) do
        begin
          JSON.parse(raw_metadata)
        rescue JSON::ParserError
          {}
        end
      end
    end

    def description
      metadata.dig('description')
    end

    def solution
      metadata.dig('solution')
    end

    def location
      metadata.fetch('location', {})
    end

    def links
      metadata.fetch('links', [])
    end
  end
end
