# frozen_string_literal: true

module Namespaces
  class ScheduleAggregationWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :update_namespace_statistics
    feature_category :source_code_management
    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find(namespace_id)
      root_ancestor = namespace.root_ancestor

      if Feature.enabled?(:remove_aggregation_schedule_lease, root_ancestor)
        Namespaces::RootStatisticsWorker.perform_async(root_ancestor.id)
      else
        schedule_through_aggregation_schedules_table(root_ancestor)
      end
    rescue ActiveRecord::RecordNotFound => ex
      Gitlab::ErrorTracking.track_exception(ex, namespace_id: namespace_id)
    end

    def schedule_through_aggregation_schedules_table(root_ancestor)
      return unless aggregation_schedules_table_exists?

      return if root_ancestor.aggregation_scheduled?

      Namespace::AggregationSchedule.safe_find_or_create_by!(namespace_id: root_ancestor.id)
    end

    private

    # On db/post_migrate/20180529152628_schedule_to_archive_legacy_traces.rb
    # traces are archived through build.trace.archive, which in consequence
    # calls UpdateProjectStatistics#schedule_namespace_statistics_worker.
    #
    # The migration and specs fails since NamespaceAggregationSchedule table
    # does not exist at that point.
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/50712
    def aggregation_schedules_table_exists?
      return true unless Rails.env.test?

      Namespace::AggregationSchedule.table_exists?
    end
  end
end
