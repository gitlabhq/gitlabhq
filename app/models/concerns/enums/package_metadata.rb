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

    def self.purl_types
      PURL_TYPES
    end

    def self.purl_types_numerical
      purl_types.invert
    end
  end
end
