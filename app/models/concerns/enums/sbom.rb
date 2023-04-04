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
      cbl_mariner: 12
    }.with_indifferent_access.freeze

    def self.component_types
      COMPONENT_TYPES
    end

    def self.purl_types
      PURL_TYPES
    end
  end
end
