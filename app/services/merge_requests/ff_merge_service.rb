module MergeRequests
  # MergeService class
  #
  # Do git merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do merge via GitLab UI
  #
  class FfMergeService < MergeRequests::BaseService
    attr_reader :merge_request

    def execute(merge_request)
      @merge_request = merge_request

      unless @merge_request.ff_merge_possible?
        return error('Merge request is not mergeable')
      end

      merge_request.in_locked_state do
        if update_head
          after_merge
          success
        else
          error('Can not merge changes')
        end
      end
    end

    private

    def update_head
      repository.ff_merge(current_user, merge_request.source_sha, merge_request.target_branch)
    end

    def after_merge
      MergeRequests::PostMergeService.new(project, current_user).execute(merge_request)
    end
  end
end
