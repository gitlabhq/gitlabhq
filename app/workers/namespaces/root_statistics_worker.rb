# frozen_string_literal: true

module Namespaces
  class RootStatisticsWorker
    include ApplicationWorker

    queue_namespace :update_namespace_statistics

    def perform(namespace_id)
      namespace = Namespace.find(namespace_id)

      return unless update_statistics_enabled_for?(namespace) && namespace.aggregation_scheduled?

      Namespaces::StatisticsRefresherService.new.execute(namespace)

      namespace.aggregation_schedule.destroy
    rescue ::Namespaces::StatisticsRefresherService::RefresherError, ActiveRecord::RecordNotFound => ex
      log_error(namespace.full_path, ex.message) if namespace
    end

    private

    def log_error(namespace_path, error_message)
      Gitlab::SidekiqLogger.error("Namespace statistics can't be updated for #{namespace_path}: #{error_message}")
    end

    def update_statistics_enabled_for?(namespace)
      Feature.enabled?(:update_statistics_namespace, namespace)
    end
  end
end
