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
          component_last_usage = Ci::Catalog::Resources::Components::LastUsage.get_usage_for(component, used_by_project)

          if component_last_usage.new_record?
            component_last_usage.last_used_date = Time.current.to_date
          else
            component_last_usage.touch(:last_used_date)
          end

          component_last_usage.save

          ServiceResponse.success(message: 'Usage recorded')
        end

        private

        attr_reader :component, :used_by_project
      end
    end
  end
end
