# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class ContainerScanningForRegistry < ContainerScanning
            private

            def type
              :container_scanning_for_registry
            end
          end
        end
      end
    end
  end
end
