# frozen_string_literal: true

module AutoMerge
  class MergeWhenPipelineSucceedsService < BaseService
    def execute(merge_request)
      return :failed unless merge_request.actual_head_pipeline

      if merge_request.actual_head_pipeline.active?
        merge_request.merge_params.merge!(params)

        unless merge_request.auto_merge_enabled?
          merge_request.auto_merge_enabled = true
          merge_request.merge_user = @current_user
          merge_request.auto_merge_strategy = AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS

          SystemNoteService.merge_when_pipeline_succeeds(merge_request, @project, @current_user, merge_request.diff_head_commit)
        end

        return :failed unless merge_request.save

        :merge_when_pipeline_succeeds
      elsif merge_request.actual_head_pipeline.success?
        # This can be triggered when a user clicks the auto merge button while
        # the tests finish at about the same time
        merge_request.merge_async(current_user.id, merge_params)

        :success
      else
        :failed
      end
    end

    def process(merge_request)
      return unless merge_request.actual_head_pipeline&.success?
      return unless merge_request.mergeable?

      merge_request.merge_async(merge_request.merge_user_id, merge_request.merge_params)
    end

    def cancel(merge_request)
      if merge_request.reset_auto_merge
        SystemNoteService.cancel_merge_when_pipeline_succeeds(merge_request, @project, @current_user)

        success
      else
        error("Can't cancel the automatic merge", 406)
      end
    end

    def available_for?(merge_request)
      merge_request.actual_head_pipeline&.active?
    end
  end
end
