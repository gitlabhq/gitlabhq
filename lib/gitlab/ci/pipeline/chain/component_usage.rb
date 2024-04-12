# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class ComponentUsage < Chain::Base
          def perform!
            included_catalog_components.each do |component|
              track_event(component)
            end
          end

          def break?
            false
          end

          private

          def track_event(component)
            Gitlab::InternalEvents.track_event(
              'ci_catalog_component_included',
              namespace: project.namespace,
              project: project,
              user: current_user,
              additional_properties: {
                label: component.project.full_path,
                property: "#{component.name}@#{component.version.name}",
                value: component.resource_type_before_type_cast
              }
            )

            ::Ci::Components::Usages::CreateService.new(component, used_by_project: project).execute
          end

          def included_catalog_components
            command.yaml_processor_result.included_components.filter_map do |hash|
              ::Ci::Catalog::ComponentsProject.new(hash[:component_project], hash[:component_sha])
                .find_catalog_component(hash[:component_name])
            end
          end
        end
      end
    end
  end
end
