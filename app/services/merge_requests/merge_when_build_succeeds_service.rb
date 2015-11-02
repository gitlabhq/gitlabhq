module MergeRequests
  class MergeWhenBuildSucceedsService < MergeRequests::BaseService
    def execute(merge_request)
      merge_request.merge_params.merge!(params[:merge_params])

      # The service is also called when the merge params are updated.
      already_approved = merge_request.merge_when_build_succeeds?

      unless already_approved
        merge_request.merge_when_build_succeeds = true
        merge_request.merge_user                = @current_user
      end

      merge_request.save

      unless already_approved
        SystemNoteService.merge_when_build_succeeds(merge_request, @project, @current_user)
      end
    end

    def trigger(build)
      merge_requests = merge_request_from(build)

      merge_requests.each do |merge_request|
        next unless merge_request.merge_when_build_succeeds?

        ci_commit = merge_request.ci_commit
        if ci_commit && ci_commit.success? && merge_request.mergeable?
          MergeWorker.perform_async(merge_request.id, merge_request.merge_user_id, merge_request.merge_params)
        end
      end
    end

    private

    def merge_request_from(build)
      merge_requests = @project.origin_merge_requests.opened.where(source_branch: build.ref).to_a
      merge_requests += @project.fork_merge_requests.opened.where(source_branch: build.ref).to_a

      merge_requests.uniq.select(&:source_project)
    end
  end
end
