# frozen_string_literal: true

# NOTE: This class is unused and to be removed in 13.1~
module Ci
  class UpdateCiRefStatusService
    include Gitlab::OptimisticLocking

    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def call
      save.tap { |success| after_save if success }
    end

    private

    def save
      might_insert = ref.new_record?

      begin
        retry_optimistic_lock(ref) do
          next false if ref.persisted? &&
            (ref.last_updated_by_pipeline_id || 0) > pipeline.id

          ref.update(status: next_status(ref.status, pipeline.status),
                     last_updated_by_pipeline: pipeline)
        end
      rescue ActiveRecord::RecordNotUnique
        if might_insert
          @ref = pipeline.reset.ref_status
          might_insert = false
          retry
        else
          raise
        end
      end
    end

    def next_status(ref_status, pipeline_status)
      if ref_status == 'failed' && pipeline_status == 'success'
        'fixed'
      else
        pipeline_status
      end
    end

    def after_save
      enqueue_pipeline_notification
    end

    def enqueue_pipeline_notification
      PipelineNotificationWorker.perform_async(pipeline.id, ref_status: ref.status)
    end

    def ref
      @ref ||= pipeline.ref_status || build_ref
    end

    def build_ref
      Ci::Ref.new(ref: pipeline.ref, project: pipeline.project, tag: pipeline.tag)
    end
  end
end
