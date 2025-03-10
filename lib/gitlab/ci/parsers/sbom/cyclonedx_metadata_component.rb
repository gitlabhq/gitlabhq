# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        class CyclonedxMetadataComponent
          REQUIRED_PROPERTIES = %w[
            name
            type
            bom-ref
          ].freeze

          def self.parse(...)
            new(...).parse
          end

          def initialize(properties)
            @properties = properties
          end

          def parse
            return if missing_properties.present?

            ::Gitlab::Ci::Reports::Sbom::Component.new(
              ref: properties['bom-ref'],
              type: properties['type'],
              name: properties['name'],
              purl: nil,
              version: nil
            )
          end

          private

          attr_reader :properties

          def missing_properties
            REQUIRED_PROPERTIES - properties&.keys.to_a
          end
        end
      end
    end
  end
end
