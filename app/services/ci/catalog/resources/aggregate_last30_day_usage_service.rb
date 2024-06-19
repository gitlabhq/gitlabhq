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

        private

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
