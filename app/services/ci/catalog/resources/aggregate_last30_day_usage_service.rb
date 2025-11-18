# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # rubocop: disable CodeReuse/ActiveRecord -- Custom queries required
      class AggregateLast30DayUsageService
        include Gitlab::Utils::StrongMemoize

        def execute
          update_component_usage_counts
          update_resource_usage_counts

          ServiceResponse.success(message: 'Usage counts updated for components and resources')
        end

        private

        def update_component_usage_counts
          Ci::Catalog::Resources::Component.find_in_batches(batch_size: 1000) do |components|
            component_ids = components.map(&:id)

            usage_counts = Ci::Catalog::Resources::Components::LastUsage
              .within_last_30_days
              .where(component_id: component_ids)
              .group(:component_id)
              .select('component_id, COUNT(DISTINCT used_by_project_id) as usage_count')
              .index_by(&:component_id)

            updates = components.map do |component|
              count = usage_counts[component.id]&.usage_count || 0
              [component.id, count]
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
          resource_counts = Component
            .group(:catalog_resource_id)
            .select('catalog_resource_id, SUM(last_30_day_usage_count) as total_usage')
            .index_by(&:catalog_resource_id)

          return if resource_counts.empty?

          updates = resource_counts.map do |resource_id, result|
            [resource_id, result.total_usage || 0]
          end

          bulk_update(
            model: Ci::Catalog::Resource,
            table_name: 'catalog_resources',
            id_column: 'id',
            update_column: 'last_30_day_usage_count',
            timestamp_column: 'last_30_day_usage_count_updated_at',
            updates: updates
          )
        end

        def bulk_update(model:, table_name:, id_column:, update_column:, timestamp_column:, updates:)
          connection = model.connection

          case_statement = updates.map do |id, count|
            "WHEN #{connection.quote(id)} THEN #{connection.quote(count)}"
          end.join(' ')

          ids_list = updates.map { |id, _| connection.quote(id) }.join(',')

          connection.execute(<<~SQL.squish)
            UPDATE #{connection.quote_table_name(table_name)}
            SET
              #{connection.quote_column_name(update_column)} = CASE #{connection.quote_column_name(id_column)} #{case_statement} END,
              #{connection.quote_column_name(timestamp_column)} = NOW()
            WHERE #{connection.quote_column_name(id_column)} IN (#{ids_list})
          SQL
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
