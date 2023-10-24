# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class DependencyScanning < BaseSource
            REQUIRED_ATTRIBUTES = [
              %w[input_file path]
            ].freeze

            private

            def type
              :dependency_scanning
            end
          end
        end
      end
    end
  end
end
