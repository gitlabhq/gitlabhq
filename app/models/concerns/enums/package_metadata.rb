# frozen_string_literal: true

module Enums
  class PackageMetadata
    PURL_TYPES = {
      composer: 1,
      conan: 2,
      gem: 3,
      golang: 4,
      maven: 5,
      npm: 6,
      nuget: 7,
      pypi: 8,
      apk: 9,
      rpm: 10,
      deb: 11,
      cbl_mariner: 12
    }.with_indifferent_access.freeze

    ADVISORY_SOURCES = {
      glad: 1, # gitlab advisory db
      trivy: 2
    }.with_indifferent_access.freeze

    DATA_TYPES = {
      advisories: 1,
      licenses: 2
    }.with_indifferent_access.freeze

    VERSION_FORMATS = {
      v1: 1,
      v2: 2
    }.with_indifferent_access.freeze

    def self.purl_types
      PURL_TYPES
    end

    def self.purl_types_numerical
      purl_types.invert
    end

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
