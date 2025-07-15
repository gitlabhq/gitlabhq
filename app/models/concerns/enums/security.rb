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
  end
end
