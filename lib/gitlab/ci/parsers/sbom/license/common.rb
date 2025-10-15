# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module License
          class Common
            def self.parse(data)
              new(data).parse
            end

            def initialize(data)
              @data = data
            end

            def parse
              license = data['license']

              return if license.blank? || license.values_at('id', 'name').all?(&:blank?)

              check_license_name!(license)
              parsed_license(license)
            end

            private

            attr_reader :data

            def check_license_name!(license)
              # Trivy 0.65.0 has a bug where it puts license identifiers in the name field.
              # To preserve license functionality for this specific version, we check if the name
              # is a valid SPDX ID and move it to the correct field if so.
              return unless ::Sbom::SPDX.valid_identifier?(license['name'])

              license['id'] = license.delete('name')
            end

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
