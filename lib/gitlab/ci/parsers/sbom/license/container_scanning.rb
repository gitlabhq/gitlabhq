# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module License
          class ContainerScanning < Common
            private

            def parsed_license(license)
              ::Gitlab::Ci::Reports::Sbom::License.new(
                spdx_identifier: license_value(license),
                name: nil,
                url: nil
              )
            end

            def license_value(license)
              # This avoids breaking changes for Trivy versions prior to v0.65.0.
              license['id'] || license['name']
            end
          end
        end
      end
    end
  end
end
