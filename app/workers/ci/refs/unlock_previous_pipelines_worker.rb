# frozen_string_literal: true

module Ci
  module Refs
    class UnlockPreviousPipelinesWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include PipelineBackgroundQueue

      idempotent!

      def perform(ref_id)
        ::Ci::Ref.find_by_id(ref_id).try do |ref|
          next unless ref.artifacts_locked?

          pipeline = ref.last_unlockable_ci_source_pipeline
          result = ::Ci::Refs::EnqueuePipelinesToUnlockService.new.execute(ref, before_pipeline: pipeline)

          log_extra_metadata_on_done(:total_pending_entries, result[:total_pending_entries])
          log_extra_metadata_on_done(:total_new_entries, result[:total_new_entries])
        end
      end
    end
  end
end
