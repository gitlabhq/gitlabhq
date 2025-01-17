# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        class Component
          include Gitlab::Utils::StrongMemoize

          TRIVY_SOURCE_PACKAGE_FIELD = 'SrcName'

          def initialize(data)
            @data = data
          end

          def parse
            ::Gitlab::Ci::Reports::Sbom::Component.new(
              ref: data['bom-ref'],
              type: data['type'],
              name: data['name'],
              purl: purl,
              version: data['version'],
              properties: properties,
              source_package_name: source_package_name,
              licenses: licenses
            )
          end

          private

          attr_reader :data

          def purl
            return unless data['purl']

            ::Sbom::PackageUrl.parse(data['purl'])
          end
          strong_memoize_attr :purl

          def properties
            CyclonedxProperties.parse_component_source(data['properties'])
          end
          strong_memoize_attr :properties

          def source_package_name
            return unless container_scanning_component?

            properties&.data&.dig(TRIVY_SOURCE_PACKAGE_FIELD) || data['name']
          end

          def container_scanning_component?
            return false unless data['purl']

            Enums::Sbom.container_scanning_purl_type?(purl.type)
          end
          strong_memoize_attr :container_scanning_component?

          def licenses
            data.fetch('licenses', []).filter_map do |license_data|
              license = License.new(license_data).parse
              next unless license

              license
            end
          end
        end
      end
    end
  end
end
