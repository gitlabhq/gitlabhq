# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class BaseSource
            REQUIRED_ATTRIBUTES = [].freeze

            def self.source(...)
              new(...).source
            end

            def initialize(data)
              @data = data
            end

            def source
              return unless required_attributes_present?

              ::Gitlab::Ci::Reports::Sbom::Source.new(
                type: type,
                data: data
              )
            end

            private

            attr_reader :data

            # Implement in child class
            # returns a symbol of the source type
            def type; end

            def required_attributes_present?
              self.class::REQUIRED_ATTRIBUTES.all? do |keys|
                data.dig(*keys).present?
              end
            end
          end
        end
      end
    end
  end
end
