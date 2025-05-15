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
                spdx_identifier: license['name'],
                name: nil,
                url: nil
              )
            end
          end
        end
      end
    end
  end
end
