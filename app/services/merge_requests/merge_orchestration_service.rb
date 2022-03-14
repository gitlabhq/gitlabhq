# frozen_string_literal: true

module MergeRequests
  class MergeOrchestrationService < ::BaseService
    def execute(merge_request)
      return unless can_merge?(merge_request)

      merge_request.update(merge_error: nil)

      if can_merge_automatically?(merge_request)
        auto_merge_service.execute(merge_request)
      else
        merge_request.merge_async(current_user.id, params)
      end
    end

    def can_merge?(merge_request)
      can_merge_automatically?(merge_request) || can_merge_immediately?(merge_request)
    end

    def preferred_auto_merge_strategy(merge_request)
      auto_merge_service.preferred_strategy(merge_request)
    end

    private

    def can_merge_immediately?(merge_request)
      merge_request.can_be_merged_by?(current_user) &&
        merge_request.mergeable?
    end

    def can_merge_automatically?(merge_request)
      auto_merge_service.available_strategies(merge_request).any?
    end

    def auto_merge_service
      @auto_merge_service ||= AutoMergeService.new(project, current_user, params)
    end
  end
end
