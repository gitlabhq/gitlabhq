# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class ContainerScanning < BaseSource
            REQUIRED_ATTRIBUTES = [
              %w[image name],
              %w[image tag],
              %w[operating_system name],
              %w[operating_system version]
            ].freeze

            private

            def type
              :container_scanning
            end
          end
        end
      end
    end
  end
end
