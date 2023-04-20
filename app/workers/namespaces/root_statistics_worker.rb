# frozen_string_literal: true

module Namespaces
  class RootStatisticsWorker
    include ApplicationWorker

    data_consistency :sticky

    sidekiq_options retry: 3

    queue_namespace :update_namespace_statistics
    feature_category :source_code_management
    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once

    def perform(namespace_id)
      namespace = Namespace.find(namespace_id)

      if Feature.enabled?(:remove_aggregation_schedule_lease, namespace)
        Namespaces::StatisticsRefresherService.new.execute(namespace)
      else
        refresh_through_namespace_aggregation_schedule(namespace)
      end

      notify_storage_usage(namespace)
    rescue ::Namespaces::StatisticsRefresherService::RefresherError, ActiveRecord::RecordNotFound => ex
      Gitlab::ErrorTracking.track_exception(ex, namespace_id: namespace_id, namespace: namespace&.full_path)
    end

    def refresh_through_namespace_aggregation_schedule(namespace)
      return unless namespace.aggregation_scheduled?

      Namespaces::StatisticsRefresherService.new.execute(namespace)

      namespace.aggregation_schedule.destroy
    end

    private

    def notify_storage_usage(namespace)
    end
  end
end

Namespaces::RootStatisticsWorker.prepend_mod_with('Namespaces::RootStatisticsWorker')
