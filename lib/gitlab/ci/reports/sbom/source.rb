# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Source
          attr_reader :source_type, :data, :fingerprint

          def initialize(type:, data:, fingerprint:)
            @source_type = type
            @data = data
            @fingerprint = fingerprint
          end
        end
      end
    end
  end
end
