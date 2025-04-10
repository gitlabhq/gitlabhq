# frozen_string_literal: true

module Ci
  module Pipelines
    class ClearPersistentRefService < CreatePersistentRefService
      def execute
        Rails.cache.delete(pipeline_persistent_ref_cache_key) if Feature.enabled?(:ci_only_one_persistent_ref_creation,
          pipeline.project)

        if Feature.enabled?(:pipeline_delete_gitaly_refs_in_batches, pipeline.project)
          pipeline.persistent_ref.async_delete
        elsif Feature.enabled?(:pipeline_cleanup_ref_worker_async, pipeline.project)
          ::Ci::PipelineCleanupRefWorker.perform_async(pipeline.id)
        else
          pipeline.persistent_ref.delete
        end
      end
    end
  end
end
