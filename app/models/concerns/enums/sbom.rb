# frozen_string_literal: true

module Enums
  class Sbom
    COMPONENT_TYPES = {
      library: 0
    }.with_indifferent_access.freeze

    PURL_TYPES = {
      composer: 1, # refered to as `packagist` in gemnasium-db
      conan: 2,
      gem: 3,
      golang: 4, # refered to as `go` in gemnasium-db
      maven: 5,
      npm: 6,
      nuget: 7,
      pypi: 8,
      apk: 9,
      rpm: 10,
      deb: 11,
      'cbl-mariner': 12,
      wolfi: 13
    }.with_indifferent_access.freeze

    DEPENDENCY_SCANNING_PURL_TYPES = %w[
      composer
      conan
      gem
      golang
      maven
      npm
      nuget
      pypi
    ].freeze

    CONTAINER_SCANNING_PURL_TYPES = %w[
      apk
      rpm
      deb
      cbl-mariner
      wolfi
    ].freeze

    def self.component_types
      COMPONENT_TYPES
    end

    def self.dependency_scanning_purl_type?(purl_type)
      DEPENDENCY_SCANNING_PURL_TYPES.include?(purl_type)
    end

    def self.container_scanning_purl_type?(purl_type)
      CONTAINER_SCANNING_PURL_TYPES.include?(purl_type)
    end

    def self.purl_types
      # return 0 by default if the purl_type is not found, to prevent
      # consumers from producing invalid SQL caused by null entries
      @_purl_types ||= PURL_TYPES.dup.tap { |h| h.default = 0 }
    end

    def self.purl_types_numerical
      purl_types.invert
    end
  end
end
