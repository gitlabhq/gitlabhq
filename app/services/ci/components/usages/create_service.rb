# frozen_string_literal: true

module Ci
  module Components
    module Usages
      class CreateService
        def initialize(component, used_by_project:)
          @component = component
          @used_by_project = used_by_project
        end

        def execute
          component_usage = Ci::Catalog::Resources::Components::Usage.new(
            component: component,
            catalog_resource: component.catalog_resource,
            project: component.project,
            used_by_project_id: used_by_project.id
          )

          if component_usage.valid?
            component_usage.save

            return ServiceResponse.success(message: 'Usage recorded')
          end

          errors = component_usage.errors

          if errors.size == 1 && errors.first.type == :taken # Only unique validation failed
            ServiceResponse.success(message: 'Usage already recorded for today')
          else
            ServiceResponse.error(message: errors.full_messages.join(', '))
          end
        end

        private

        attr_reader :component, :used_by_project
      end
    end
  end
end
