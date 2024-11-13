# frozen_string_literal: true

module Ci
  module Components
    module Usages
      class CreateService
        ValidationError = Class.new(StandardError)

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

          component_last_usage = Ci::Catalog::Resources::Components::LastUsage.get_usage_for(component, used_by_project)

          if component_last_usage.new_record?
            component_last_usage.last_used_date = Time.current.to_date
          else
            component_last_usage.touch(:last_used_date)
          end

          component_last_usage.save # Save last usage regardless of component_usage

          if component_usage.save
            ServiceResponse.success(message: 'Usage recorded')
          else
            errors = component_usage.errors || component_last_usage.errors

            if errors.size == 1 && errors.first.type == :taken
              ServiceResponse.success(message: 'Usage already recorded for today')
            else
              exception = ValidationError.new(errors.full_messages.join(', '))

              Gitlab::ErrorTracking.track_exception(exception)
              ServiceResponse.error(message: exception.message)
            end
          end
        end

        private

        attr_reader :component, :used_by_project
      end
    end
  end
end
