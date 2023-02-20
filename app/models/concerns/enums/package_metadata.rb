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
      pypi: 8
    }.with_indifferent_access.freeze

    def self.purl_types
      PURL_TYPES
    end
  end
end
