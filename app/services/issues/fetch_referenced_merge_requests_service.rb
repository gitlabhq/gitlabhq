module Issues
  class FetchReferencedMergeRequestsService < Issues::BaseService
    def execute(issue)
      referenced_merge_requests = issue.referenced_merge_requests(current_user)
      referenced_merge_requests = Gitlab::IssuableSorter.sort(project, referenced_merge_requests) { |i| i.iid.to_s }
      closed_by_merge_requests = issue.closed_by_merge_requests(current_user)
      closed_by_merge_requests = Gitlab::IssuableSorter.sort(project, closed_by_merge_requests) { |i| i.iid.to_s }

      [referenced_merge_requests, closed_by_merge_requests]
    end
  end
end
