# frozen_string_literal: true

module Ci
  module Components
    module Usages
      class CreateService
        ValidationError = Class.new(StandardError)

        def initialize(catalog_components, used_by_project:)
          @catalog_components = catalog_components
          @used_by_project = used_by_project
          @current_date = Time.current.to_date
        end

        def execute
          return ServiceResponse.success(message: 'No components to process') if catalog_components.empty?

          existing_usages = fetch_existing_usages
          records_to_insert, records_to_update = partition_usage_records(existing_usages)
          persist_usage_records(records_to_update, records_to_insert)

          ServiceResponse.success(message: 'Usages recorded')
        end

        private

        attr_reader :catalog_components, :used_by_project, :current_date

        def fetch_existing_usages
          component_ids = catalog_components.map { |data| data[:component].id }

          ::Ci::Catalog::Resources::Components::LastUsage
            .where(component_id: component_ids, used_by_project_id: used_by_project.id) # rubocop:disable CodeReuse/ActiveRecord -- batch loading required for performance
            .index_by(&:component_id)
        end

        def partition_usage_records(existing_usages)
          records_to_insert = []
          records_to_update = []

          catalog_components.each do |data|
            component = data[:component]

            if existing_usages[component.id]
              records_to_update << existing_usages[component.id]
            else
              records_to_insert << build_usage_record(component)
            end
          end

          [records_to_insert, records_to_update]
        end

        def build_usage_record(component)
          {
            component_id: component.id,
            used_by_project_id: used_by_project.id,
            catalog_resource_id: component.catalog_resource_id,
            component_project_id: component.project_id,
            last_used_date: current_date
          }
        end

        def persist_usage_records(records_to_update, records_to_insert)
          if records_to_update.any?
            ::Ci::Catalog::Resources::Components::LastUsage
              .where(id: records_to_update.map(&:id)) # rubocop:disable CodeReuse/ActiveRecord -- batch update required for performance
              .update_all(last_used_date: current_date)
          end

          ::Ci::Catalog::Resources::Components::LastUsage.insert_all(records_to_insert) if records_to_insert.any?
        end
      end
    end
  end
end
