# frozen_string_literal: true

module AutoMerge
  class MergeWhenPipelineSucceedsService < AutoMerge::BaseService
    def execute(merge_request)
      super do
        add_system_note(merge_request)
      end
    end

    def process(merge_request)
      logger.info("Processing Automerge - MWPS")
      return unless merge_request.diff_head_pipeline_success?

      logger.info("Pipeline Success - MWPS")
      return unless merge_request.mergeable?

      logger.info("Merge request mergeable - MWPS")

      merge_request.merge_async(merge_request.merge_user_id, merge_request.merge_params)
    end

    def cancel(merge_request)
      super do
        SystemNoteService.cancel_merge_when_pipeline_succeeds(merge_request, project, current_user)
      end
    end

    def abort(merge_request, reason)
      super do
        SystemNoteService.abort_merge_when_pipeline_succeeds(merge_request, project, current_user, reason)
      end
    end

    def available_for?(_merge_request)
      false
    end

    private

    def add_system_note(merge_request)
      SystemNoteService.merge_when_pipeline_succeeds(merge_request, project, current_user, merge_request.diff_head_pipeline.sha) if merge_request.saved_change_to_auto_merge_enabled?
    end

    def notify(merge_request)
      notification_service.async.merge_when_pipeline_succeeds(merge_request, current_user) if merge_request.saved_change_to_auto_merge_enabled?
    end
  end
end
