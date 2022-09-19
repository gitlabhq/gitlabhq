# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class DependencyScanning
            REQUIRED_ATTRIBUTES = [
              %w[input_file path]
            ].freeze

            def self.source(...)
              new(...).source
            end

            def initialize(data)
              @data = data
            end

            def source
              return unless required_attributes_present?

              ::Gitlab::Ci::Reports::Sbom::Source.new(
                type: :dependency_scanning,
                data: data
              )
            end

            private

            attr_reader :data

            def required_attributes_present?
              REQUIRED_ATTRIBUTES.all? do |keys|
                data.dig(*keys).present?
              end
            end
          end
        end
      end
    end
  end
end
