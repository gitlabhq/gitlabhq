# frozen_string_literal: true

module MergeRequests
  class AfterCreateService < MergeRequests::BaseService
    def execute(merge_request)
      event_service.open_mr(merge_request, current_user)
      notification_service.new_merge_request(merge_request, current_user)

      # https://gitlab.com/gitlab-org/gitlab/issues/208813
      if ::Feature.enabled?(:create_merge_request_pipelines_in_sidekiq, project)
        create_pipeline_for(merge_request, current_user)
        merge_request.update_head_pipeline
      end

      merge_request.diffs(include_stats: false).write_cache
      merge_request.create_cross_references!(current_user)
    end
  end
end
