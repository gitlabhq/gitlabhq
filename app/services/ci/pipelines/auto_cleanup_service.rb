# frozen_string_literal: true

module Ci
  module Pipelines
    class AutoCleanupService
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 50
      OTHER_STATUSES_GROUP = 'other'

      def initialize(project:)
        @project = project
        @processing_cache = cache_store.read
      end

      def execute
        destroyable_pipelines, skipped_pipelines = load_destroyable_pipelines

        Ci::DestroyPipelineService
          .new(project, nil)
          .unsafe_execute(destroyable_pipelines, skip_cancel: true)

        ServiceResponse.success(payload: { destroyed_pipelines_size: destroyable_pipelines.size,
                                           skipped_pipelines_size: skipped_pipelines.size })
      end

      private

      attr_reader :project, :processing_cache

      def load_destroyable_pipelines
        pipelines = status_groups.flat_map do |group_name, statuses|
          with_processing_cache(group_name, statuses) do |last_processed_at|
            load_pipelines_batch(statuses, last_processed_at)
          end
        end

        flush_processing_cache

        pipelines.partition { |pipeline| can_be_destroyed?(pipeline) }
      end

      def status_groups
        mapping = Ci::HasStatus::COMPLETED_WITH_MANUAL_STATUSES.index_with(&:itself)

        Ci::HasStatus::AVAILABLE_STATUSES
          .group_by { |status| mapping.fetch(status, OTHER_STATUSES_GROUP) }
      end

      def with_processing_cache(group_name, statuses)
        last_processed_at = processing_cache.fetch(group_name) { min_created_at_for_statuses(statuses) }

        return [] if processing_complete_for_group?(last_processed_at)

        pipelines = yield(last_processed_at)
        processing_cache[group_name] = pipelines.last&.created_at || deletion_cutoff_time

        pipelines
      end

      def processing_complete_for_group?(last_processed_at)
        last_processed_at.nil? || last_processed_at >= deletion_cutoff_time
      end

      def load_pipelines_batch(statuses, created_after)
        Ci::Pipeline
          .for_project(project.id)
          .for_status(statuses)
          .created_before(deletion_cutoff_time)
          .created_on_or_after(created_after)
          .order_created_at_asc_id_asc
          .take(BATCH_SIZE) # rubocop:disable CodeReuse/ActiveRecord -- specific to this service
      end

      def min_created_at_for_statuses(statuses)
        Ci::Pipeline.for_project(project.id).for_status(statuses).minimum(:created_at)
      end

      def flush_processing_cache
        cache_store.write(processing_cache)
      end

      def can_be_destroyed?(pipeline)
        return false if skip_protected_pipelines? && pipeline.protected?
        return false if skip_locked_pipelines? && pipeline.artifacts_locked?

        true
      end

      def deletion_cutoff_time
        project.ci_delete_pipelines_in_seconds.seconds.ago
      end
      strong_memoize_attr :deletion_cutoff_time

      def cache_store
        ::Ci::RetentionPolicies::PipelineDeletionCutoffCache.new(project: project)
      end
      strong_memoize_attr :cache_store

      def skip_protected_pipelines?
        Feature.enabled?(:ci_skip_old_protected_pipelines, project.root_namespace, type: :wip)
      end
      strong_memoize_attr :skip_protected_pipelines?

      def skip_locked_pipelines?
        Feature.enabled?(:ci_skip_locked_pipelines, project.root_namespace, type: :wip)
      end
      strong_memoize_attr :skip_locked_pipelines?
    end
  end
end
