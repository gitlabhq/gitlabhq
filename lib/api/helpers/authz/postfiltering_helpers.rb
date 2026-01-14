# frozen_string_literal: true

module API
  module Helpers
    module Authz
      module PostfilteringHelpers
        def filter_with_logging(collection:, filter_proc:, resource_type:)
          if current_user.present? && Feature.enabled?(:postfilter_logging, current_user)
            filtered = nil
            postfilter_duration = Benchmark.realtime do
              filtered = filter_proc.call
            end

            collection_size = collection.to_a.size
            Gitlab::AppLogger.info(
              message: "Post-filtering - #{resource_type}",
              redacted_count: collection_size - filtered.size,
              collection_count: collection_size,
              postfiltering_duration: postfilter_duration,
              user_id: current_user.id
            )

            filtered
          else
            filter_proc.call
          end
        rescue StandardError => e
          Gitlab::AppLogger.warn(
            message: "Post-filtering failed - #{resource_type}",
            error_class: e.class.name,
            error_message: e.message,
            user_id: current_user&.id
          )

          raise e
        end
      end
    end
  end
end
