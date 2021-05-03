# frozen_string_literal: true

module Packages
  module Composer
    class CacheCleanupWorker
      include ApplicationWorker

      sidekiq_options retry: 3
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      feature_category :package_registry
      tags :exclude_from_kubernetes

      idempotent!

      def perform
        ::Packages::Composer::CacheFile.without_namespace.find_in_batches do |cache_files|
          cache_files.each(&:destroy)
        rescue ActiveRecord::RecordNotFound
          # ignore. likely due to object already being deleted.
        end

        ::Packages::Composer::CacheFile.expired.find_in_batches do |cache_files|
          cache_files.each(&:destroy)
        rescue ActiveRecord::RecordNotFound
          # ignore. likely due to object already being deleted.
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e)
      end
    end
  end
end
