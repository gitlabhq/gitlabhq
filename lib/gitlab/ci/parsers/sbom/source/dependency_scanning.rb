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

              {
                'type' => :dependency_scanning,
                'data' => data,
                'fingerprint' => fingerprint
              }
            end

            private

            attr_reader :data

            def required_attributes_present?
              REQUIRED_ATTRIBUTES.all? do |keys|
                data.dig(*keys).present?
              end
            end

            def fingerprint
              Digest::SHA256.hexdigest(data.to_json)
            end
          end
        end
      end
    end
  end
end
