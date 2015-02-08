module MergeRequests
  class BaseMergeService < MergeRequests::BaseService

    private

    def create_merge_event(merge_request, current_user)
      EventCreateService.new.merge_mr(merge_request, current_user)
    end
  end
end
