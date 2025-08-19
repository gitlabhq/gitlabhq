# frozen_string_literal: true

module Enums # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Security
    extend ActiveSupport::Concern

    ANALYZER_TYPES = {
      sast: 0,
      sast_advanced: 1,
      sast_iac: 2,
      dast: 3,
      dependency_scanning: 4,
      container_scanning: 5,
      secret_detection: 6,
      coverage_fuzzing: 7,
      api_fuzzing: 8,
      cluster_image_scanning: 9
    }.freeze

    ANALYZER_STATUSES = {
      not_configured: 0,
      success: 1,
      failed: 2
    }.freeze

    EDITABLE_STATES = {
      locked: 0,
      editable_attributes: 10,
      editable: 20
    }.freeze

    DEFAULT_CONFIGURATION_SOURCE = :sbom

    CONFIGURATION_SOURCE_TYPES = {
      DEFAULT_CONFIGURATION_SOURCE => 0,
      pmdb: 1
    }.with_indifferent_access.freeze

    def self.analyzer_types
      ANALYZER_TYPES
    end

    def self.extended_analyzer_types
      ANALYZER_TYPES.merge({
        secret_detection_secret_push_protection: 10,
        container_scanning_for_registry: 11,
        secret_detection_pipeline_based: 12,
        container_scanning_pipeline_based: 13
      })
    end

    def self.analyzer_statuses
      ANALYZER_STATUSES
    end

    def self.editable_states
      EDITABLE_STATES
    end

    def self.configuration_source_types
      CONFIGURATION_SOURCE_TYPES
    end
  end
end
