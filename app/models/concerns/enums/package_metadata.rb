# frozen_string_literal: true

module Enums
  class PackageMetadata
    ADVISORY_SOURCES = {
      glad: 1, # gitlab advisory db
      'trivy-db': 2
    }.with_indifferent_access.freeze

    DATA_TYPES = {
      advisories: 1,
      licenses: 2,
      cve_enrichment: 3
    }.with_indifferent_access.freeze

    VERSION_FORMATS = {
      v1: 1,
      v2: 2
    }.with_indifferent_access.freeze

    def self.advisory_sources
      ADVISORY_SOURCES
    end

    def self.data_types
      DATA_TYPES
    end

    def self.version_formats
      VERSION_FORMATS
    end
  end
end
