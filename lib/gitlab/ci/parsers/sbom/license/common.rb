# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module License
          class Common
            def self.parse(data, is_container_scanning)
              license = is_container_scanning ? ContainerScanning.new(data) : new(data)
              license.parse
            end

            def initialize(data)
              @data = data
            end

            def parse
              license = data['license']
              return unless license

              # A license must have either id or name
              return unless license['id'].present? || license['name'].present?

              parsed_license(license)
            end

            private

            attr_reader :data

            def parsed_license(license)
              ::Gitlab::Ci::Reports::Sbom::License.new(
                spdx_identifier: license['id'],
                name: license['name'],
                url: license['url']
              )
            end
          end
        end
      end
    end
  end
end
