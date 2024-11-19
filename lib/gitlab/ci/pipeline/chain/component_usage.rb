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
                label: component.id.to_s,
                value: component.component_type_before_type_cast
              }
            )

            ::Ci::Components::Usages::CreateService.new(component, used_by_project: project).execute
          end

          def included_catalog_components
            command.yaml_processor_result.included_components.filter_map do |hash|
              ::Ci::Catalog::ComponentsProject.new(hash[:project], hash[:sha])
                .find_catalog_component(hash[:name])
            end
          end
        end
      end
    end
  end
end
