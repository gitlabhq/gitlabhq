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

            # rubocop:disable Gitlab/NoCodeCoverageComment -- method is tested in EE
            # :nocov:
            # Overridden in EE
            def parse
              license = data['license']

              return if license.blank? || license.values_at('id').all?(&:blank?)

              parsed_license(license)
            end
            # :nocov:
            # rubocop:enable Gitlab/NoCodeCoverageComment

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

Gitlab::Ci::Parsers::Sbom::License::Common.prepend_mod
