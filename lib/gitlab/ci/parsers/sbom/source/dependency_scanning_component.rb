# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class DependencyScanningComponent < BaseSource
            REQUIRED_ATTRIBUTES = [
              %w[reachability]
            ].freeze

            private

            def type
              :dependency_scanning_component
            end
          end
        end
      end
    end
  end
end
