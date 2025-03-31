# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        class License
          def initialize(data)
            @data = data
          end

          def parse
            license = data['license']
            return unless license

            # A license must have either id or name
            return unless license['id'].present? || license['name'].present?

            ::Gitlab::Ci::Reports::Sbom::License.new(
              spdx_identifier: license['id'],
              name: license['name'],
              url: license['url']
            )
          end

          private

          attr_reader :data
        end
      end
    end
  end
end
