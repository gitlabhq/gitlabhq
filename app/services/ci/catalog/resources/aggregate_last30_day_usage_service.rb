# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This service aggregates CI component usage data and updates `last_30_day_usage_count` for
      # each catalog resource daily. It utilizes Gitlab::Ci::Components::Usages::Aggregator which
      # implements a "continue later" mechanism to process the data in time-boxed jobs.
      # rubocop: disable CodeReuse/ActiveRecord -- Custom queries required
      class AggregateLast30DayUsageService
        include Gitlab::Utils::StrongMemoize

        TARGET_MODEL = Ci::Catalog::Resource
        GROUP_BY_COLUMN = :catalog_resource_id
        WINDOW_LENGTH = 30.days

        def execute
          return execute_with_new_table if ::Feature.enabled?(:ci_catalog_ranking_from_new_usage_table, :instance)

          return ServiceResponse.success(message: "Processing complete for #{today}") if done_processing?

          aggregator = Gitlab::Ci::Components::Usages::Aggregator.new(
            target_model: TARGET_MODEL,
            group_by_column: GROUP_BY_COLUMN,
            usage_start_date: today - WINDOW_LENGTH,
            usage_end_date: today - 1.day,
            lease_key: lease_key
          )

          result = aggregator.each_batch do |usage_counts|
            save_usage_counts!(usage_counts)
          end

          if result
            ServiceResponse.success(message: 'Targets processed', payload: result.to_h)
          else
            ServiceResponse.success(message: 'Lease taken', payload: { lease_key: lease_key })
          end
        end

        def execute_with_new_table
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

        # NOTE: New catalog resources added today are considered already processed
        # because their `last_30_day_usage_count_updated_at` is defaulted to NOW().
        def done_processing?
          min_updated_at = TARGET_MODEL.minimum(:last_30_day_usage_count_updated_at)
          return true unless min_updated_at

          min_updated_at >= today.to_time
        end

        def save_usage_counts!(usage_counts)
          mapping = usage_counts.transform_values { |v| { last_30_day_usage_count: v } }
          catalog_resource_ids = usage_counts.keys.map(&:id)

          TARGET_MODEL.transaction do
            Gitlab::Database::BulkUpdate.execute(%i[last_30_day_usage_count], mapping)

            # Gitlab::Database::BulkUpdate does not support column type
            # `:timestamptz` so we must update the timestamps separately.
            TARGET_MODEL
              .where(id: catalog_resource_ids)
              .update_all(last_30_day_usage_count_updated_at: Time.current)
          end
        end

        def today
          Date.today
        end
        strong_memoize_attr :today

        def lease_key
          self.class.name
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
