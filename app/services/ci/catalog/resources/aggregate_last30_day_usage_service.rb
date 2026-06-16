# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # rubocop: disable CodeReuse/ActiveRecord -- Custom queries required
      # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- plucked relations are limited by the batch size
      class AggregateLast30DayUsageService
        BATCH_SIZE = 1000

        def execute
          update_component_usage_counts
          update_resource_usage_counts

          ServiceResponse.success(message: 'Usage counts updated for components and resources')
        end

        private

        def update_component_usage_counts
          Ci::Catalog::Resources::Component.each_batch(of: BATCH_SIZE) do |components|
            component_ids = components.pluck(:id)

            usage_counts = Ci::Catalog::Resources::Components::LastUsage
              .within_last_30_days
              .where(component_id: component_ids)
              .group(:component_id)
              .select('component_id, COUNT(DISTINCT used_by_project_id) as usage_count')
              .index_by(&:component_id)

            updates = component_ids.map do |component_id|
              count = usage_counts[component_id]&.usage_count || 0
              [component_id, count]
            end

            next if updates.empty?

            bulk_update(
              model: Ci::Catalog::Resources::Component,
              table_name: 'catalog_resource_components',
              id_column: 'id',
              update_column: 'last_30_day_usage_count',
              timestamp_column: 'last_30_day_usage_count_updated_at',
              updates: updates
            )
          end
        end

        def update_resource_usage_counts
          Ci::Catalog::Resource.published.each_batch(of: BATCH_SIZE) do |resources|
            resource_ids = resources.pluck(:id)

            usage_counts = Component
              .where(catalog_resource_id: resource_ids)
              .group(:catalog_resource_id)
              .select('catalog_resource_id, SUM(last_30_day_usage_count) as total_usage')
              .index_by(&:catalog_resource_id)

            updates = resource_ids.map do |resource_id|
              count = usage_counts[resource_id]&.total_usage || 0
              [resource_id, count]
            end

            next if updates.empty?

            bulk_update(
              model: Ci::Catalog::Resource,
              table_name: 'catalog_resources',
              id_column: 'id',
              update_column: 'last_30_day_usage_count',
              timestamp_column: 'last_30_day_usage_count_updated_at',
              updates: updates
            )
          end
        end

        def bulk_update(model:, table_name:, id_column:, update_column:, timestamp_column:, updates:)
          connection = model.connection

          case_statement = updates.map do |id, count|
            "WHEN #{connection.quote(id)} THEN #{connection.quote(count)}"
          end.join(' ')

          ids_list = updates.map { |id, _| connection.quote(id) }.join(',')

          connection.execute(<<~SQL.squish)
            UPDATE #{model.adapter_class.quote_table_name(table_name)}
            SET
              #{model.adapter_class.quote_column_name(update_column)} = CASE #{model.adapter_class.quote_column_name(id_column)} #{case_statement} END,
              #{model.adapter_class.quote_column_name(timestamp_column)} = NOW()
            WHERE #{model.adapter_class.quote_column_name(id_column)} IN (#{ids_list})
          SQL
        end
      end
      # rubocop: enable Database/AvoidUsingPluckWithoutLimit
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
