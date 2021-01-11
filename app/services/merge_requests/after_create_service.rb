# frozen_string_literal: true

module MergeRequests
  class AfterCreateService < MergeRequests::BaseService
    def execute(merge_request)
      event_service.open_mr(merge_request, current_user)
      merge_request_activity_counter.track_create_mr_action(user: current_user)
      notification_service.new_merge_request(merge_request, current_user)

      create_pipeline_for(merge_request, current_user)
      merge_request.update_head_pipeline

      merge_request.diffs(include_stats: false).write_cache
      merge_request.create_cross_references!(current_user)

      OnboardingProgressService.new(merge_request.target_project.namespace).execute(action: :merge_request_created)
    end
  end
end

MergeRequests::AfterCreateService.prepend_if_ee('EE::MergeRequests::AfterCreateService')
