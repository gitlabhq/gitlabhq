# frozen_string_literal: true

module Namespaces
  class ScheduleAggregationWorker
    include ApplicationWorker

    queue_namespace :update_namespace_statistics

    def perform(namespace_id)
      return unless aggregation_schedules_table_exists?

      namespace = Namespace.find(namespace_id)
      root_ancestor = namespace.root_ancestor

      return if root_ancestor.aggregation_scheduled?

      Namespace::AggregationSchedule.safe_find_or_create_by!(namespace_id: root_ancestor.id)
    rescue ActiveRecord::RecordNotFound
      log_error(namespace_id)
    end

    private

    # On db/post_migrate/20180529152628_schedule_to_archive_legacy_traces.rb
    # traces are archived through build.trace.archive, which in consequence
    # calls UpdateProjectStatistics#schedule_namespace_statistics_worker.
    #
    # The migration and specs fails since NamespaceAggregationSchedule table
    # does not exist at that point.
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/50712
    def aggregation_schedules_table_exists?
      return true unless Rails.env.test?

      Namespace::AggregationSchedule.table_exists?
    end

    def log_error(root_ancestor_id)
      Gitlab::SidekiqLogger.error("Namespace can't be scheduled for aggregation: #{root_ancestor_id} does not exist")
    end
  end
end
