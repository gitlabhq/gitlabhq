# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker-- Spawns non-idempotent ExportWorker jobs
module Ci
  module Observability
    class GroupExportWorker
      include ApplicationWorker

      deduplicate :until_executed
      queue_namespace :pipeline_hooks
      worker_resource_boundary :cpu
      data_consistency :delayed
      sidekiq_options retry: 3
      sidekiq_options dead: false
      feature_category :observability
      urgency :low

      defer_on_database_health_signal :gitlab_main

      COLLECTION_WINDOW_LOOKBACK_DAYS = 10

      def perform(group_id, params = {})
        params.symbolize_keys!
        collection_window_lookback_days = params.fetch(:collection_window_lookback_days,
          COLLECTION_WINDOW_LOOKBACK_DAYS).to_i

        unless collection_window_lookback_days > 0
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
            ArgumentError.new('collection_window_lookback_days must be a positive number')
          )
          return
        end

        @collection_window_lookback_days = collection_window_lookback_days.days.ago
        group = ::Group.find_by_id(group_id)
        return unless group

        export_descendant_projects_for_group(group)
      end

      private

      attr_reader :collection_window_lookback_days

      def export_descendant_projects_for_group(group)
        all_project_ids = group.all_unarchived_project_ids
        return if all_project_ids.empty?

        descendant_groups_with_settings = find_descendant_groups_with_observability_settings(group)
        excluded_project_ids = collect_project_ids_from_groups(descendant_groups_with_settings)
        project_ids_to_process = all_project_ids - excluded_project_ids
        return if project_ids_to_process.empty?

        enqueue_pipelines_for_project_ids(project_ids_to_process)
      end

      def find_descendant_groups_with_observability_settings(group)
        descendant_ids = group.descendant_ids
        groups_with_settings_ids = find_groups_with_observability_settings(descendant_ids)
        ::Group.id_in(groups_with_settings_ids).as_ids
      end

      def collect_project_ids_from_groups(groups)
        namespace_ids = Gitlab::ObjectHierarchy.new(::Group.id_in(groups))
          .base_and_descendants
          .select(:id)

        Project.self_and_ancestors_non_archived
          .in_namespace(namespace_ids)
          .select(:id)
      end

      def find_groups_with_observability_settings(group_ids)
        ::Observability::GroupO11ySetting
          .search_by_group_id(group_ids)
          .select(:group_id)
      end

      def enqueue_pipelines_for_project_ids(project_ids)
        project_ids.each_slice(ApplicationRecord::MAX_PLUCK) do |project_ids_batch|
          completed_pipelines = Ci::Pipeline
            .for_project(project_ids_batch)
            .for_status(Ci::Pipeline.completed_statuses)
            .created_on_or_after(collection_window_lookback_days)
            .ids # rubocop:disable CodeReuse/ActiveRecord -- the number of returned IDs is limited and the logic is specific

          next if completed_pipelines.empty?

          Ci::Observability::ExportWorker.bulk_perform_async_with_contexts(
            completed_pipelines,
            arguments_proc: ->(pipeline_id) { [pipeline_id] },
            context_proc: ->(_) { {} } # No project context because loading the project is wasteful
          )
        end
      end
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
