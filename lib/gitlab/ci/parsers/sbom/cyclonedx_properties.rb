# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        # Parses GitLab CycloneDX metadata properties which are defined by the taxonomy at
        # https://gitlab.com/gitlab-org/security-products/gitlab-cyclonedx-property-taxonomy
        #
        # This parser knows how to process schema version 1 and will not attempt to parse
        # later versions. Each source type has it's own namespace in the property schema,
        # and is also given its own parser. Properties are filtered by namespace,
        # and then passed to each source parser for processing.
        class CyclonedxProperties
          SUPPORTED_SCHEMA_VERSION = '1'
          GITLAB_PREFIX = 'gitlab:'
          SOURCE_PARSERS = {
            'dependency_scanning' => ::Gitlab::Ci::Parsers::Sbom::Source::DependencyScanning
          }.freeze
          SUPPORTED_PROPERTIES = %w[
            meta:schema_version
            dependency_scanning:category
            dependency_scanning:input_file:path
            dependency_scanning:source_file:path
            dependency_scanning:package_manager:name
            dependency_scanning:language:name
          ].freeze

          def self.parse_source(...)
            new(...).parse_source
          end

          def initialize(properties)
            @properties = properties
          end

          def parse_source
            return unless properties.present?
            return unless supported_schema_version?

            source
          end

          private

          attr_reader :properties

          def property_data
            @property_data ||= properties
              .each_with_object({}) { |property, data| parse_property(property, data) }
          end

          def parse_property(property, data)
            name = property['name']
            value = property['value']

            # The specification permits the name or value to be absent.
            return unless name.present? && value.present?
            return unless name.start_with?(GITLAB_PREFIX)

            namespaced_name = name.delete_prefix(GITLAB_PREFIX)

            return unless SUPPORTED_PROPERTIES.include?(namespaced_name)

            parse_name_value_pair(namespaced_name, value, data)
          end

          def parse_name_value_pair(name, value, data)
            # Each namespace in the property name reflects a key in the hash.
            # A property with the name `dependency_scanning:input_file:path`
            # and the value `package-lock.json` should be transformed into
            # this data:
            # {"dependency_scanning": {"input_file": {"path": "package-lock.json"}}}
            keys = name.split(':')

            # Remove last item from the keys and use it to create
            # the initial object.
            last = keys.pop

            # Work backwards. For each key, create a new hash wrapping the previous one.
            # Using `dependency_scanning:input_file:path` as an example:
            #
            # 1. memo = { "path" => "package-lock.json" } (arguments given to reduce)
            # 2. memo = { "input_file" => memo }
            # 3. memo = { "dependency_scanning" => memo }
            property = keys.reverse.reduce({ last => value }) do |memo, key|
              { key => memo }
            end

            data.deep_merge!(property)
          end

          def schema_version
            @schema_version ||= property_data.dig('meta', 'schema_version')
          end

          def supported_schema_version?
            schema_version == SUPPORTED_SCHEMA_VERSION
          end

          def source
            @source ||= property_data
              .slice(*SOURCE_PARSERS.keys)
              .lazy
              .filter_map { |namespace, data| SOURCE_PARSERS[namespace].source(data) }
              .first
          end
        end
      end
    end
  end
end
