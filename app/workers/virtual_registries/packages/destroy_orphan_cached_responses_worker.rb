# frozen_string_literal: true

module VirtualRegistries
  module Packages
    class DestroyOrphanCachedResponsesWorker
      include ApplicationWorker
      include LimitedCapacity::Worker

      MAX_CAPACITY = 2

      data_consistency :sticky
      urgency :low
      idempotent!

      queue_namespace :dependency_proxy_blob
      feature_category :virtual_registry

      def perform_work(model)
        next_item = next_item(model.constantize)

        return unless next_item

        next_item.destroy!
        log_metadata(next_item)
      rescue StandardError => exception
        next_item&.update_column(:status, :error) unless next_item&.destroyed?

        Gitlab::ErrorTracking.log_exception(
          exception,
          class: self.class.name
        )
      end

      def remaining_work_count(model)
        model.constantize.pending_destruction.limit(max_running_jobs + 1).count
      end

      def max_running_jobs
        MAX_CAPACITY
      end

      private

      def next_item(klass)
        klass.transaction do
          next_item = klass.next_pending_destruction

          if next_item
            next_item.update_column(:status, :processing)
            log_cleanup_item(next_item)
          end

          next_item
        end
      end

      def log_metadata(cached_response)
        log_extra_metadata_on_done(:cached_response_id, cached_response.id)
        log_extra_metadata_on_done(:group_id, cached_response.group_id)
        log_extra_metadata_on_done(:relative_path, cached_response.relative_path)
      end

      def log_cleanup_item(cached_response)
        logger.info(
          structured_payload(
            cached_response_id: cached_response.id
          )
        )
      end
    end
  end
end
