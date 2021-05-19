# frozen_string_literal: true

module Namespaces
  class RootStatisticsWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :update_namespace_statistics
    feature_category :source_code_management
    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find(namespace_id)

      return unless namespace.aggregation_scheduled?

      Namespaces::StatisticsRefresherService.new.execute(namespace)

      namespace.aggregation_schedule.destroy
    rescue ::Namespaces::StatisticsRefresherService::RefresherError, ActiveRecord::RecordNotFound => ex
      Gitlab::ErrorTracking.track_exception(ex, namespace_id: namespace_id, namespace: namespace&.full_path)
    end
  end
end
