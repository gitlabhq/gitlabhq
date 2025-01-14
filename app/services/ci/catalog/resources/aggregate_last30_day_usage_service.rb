# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # rubocop: disable CodeReuse/ActiveRecord -- Custom queries required
      class AggregateLast30DayUsageService
        include Gitlab::Utils::StrongMemoize

        def execute
          update_component_counts
          update_resource_counts

          ServiceResponse.success(message: 'Usage counts updated for components and resources')
        end

        private

        def update_component_counts
          Ci::Catalog::Resources::Component.find_each(batch_size: 1000) do |component|
            usage_count = component
              .last_usages
              .select(:used_by_project_id)
              .distinct
              .count

            component.update_columns(
              last_30_day_usage_count: usage_count
            )
          end
        end

        def update_resource_counts
          # Using a subquery to sum component counts for each resource
          resource_counts = Component
            .group(:catalog_resource_id)
            .select(
              :catalog_resource_id,
              'SUM(last_30_day_usage_count) as total_usage'
            )

          resource_counts.each do |result|
            Ci::Catalog::Resource.where(id: result.catalog_resource_id).update_all(
              last_30_day_usage_count: result.total_usage
            )
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
