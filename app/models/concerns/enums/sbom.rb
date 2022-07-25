# frozen_string_literal: true

module Enums
  class Sbom
    COMPONENT_TYPES = {
      library: 0
    }.with_indifferent_access.freeze

    def self.component_types
      COMPONENT_TYPES
    end
  end
end
