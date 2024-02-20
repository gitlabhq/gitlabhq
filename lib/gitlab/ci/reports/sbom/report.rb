# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Report
          # This represents the attributes defined in cycloneDX Schema
          # https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/validators/json_schemas/cyclonedx_report.json#L7
          BOM_FORMAT = 'CycloneDX'
          SPEC_VERSION = '1.4'
          VERSION = 1

          attr_reader :source, :errors
          attr_accessor :sbom_attributes, :metadata, :components

          def initialize
            @sbom_attributes = {
              bom_format: BOM_FORMAT,
              spec_version: SPEC_VERSION,
              serial_number: "urn:uuid:#{SecureRandom.uuid}",
              version: VERSION
            }
            @components = []
            @metadata = ::Gitlab::Ci::Reports::Sbom::Metadata.new
            @dependencies = DependencyAdjacencyList.new
            @errors = []
          end

          def valid?
            errors.empty?
          end

          def add_error(error)
            errors << error
          end

          def set_source(source)
            self.source = source
          end

          def add_component(component)
            components << component
            dependencies.add_component_info(component.ref, component.name, component.version)
          end

          def add_dependency(parent, child)
            dependencies.add_edge(parent, child)
          end

          def ensure_ancestors!
            components.each do |component|
              component.ancestors = ancestors_for(component.ref)
            end
          end

          private

          def ancestors_for(ref)
            dependencies.ancestors_for(ref)
          end

          attr_writer :source
          attr_reader :dependencies
        end
      end
    end
  end
end
