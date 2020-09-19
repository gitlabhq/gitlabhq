# frozen_string_literal: true

class MergeRequestSidebarExtrasEntity < IssuableSidebarExtrasEntity
  expose :assignees do |merge_request|
    MergeRequestAssigneeEntity.represent(merge_request.assignees, merge_request: merge_request)
  end

  expose :reviewers, if: -> (m) { m.allows_reviewers? } do |merge_request|
    MergeRequestReviewerEntity.represent(merge_request.reviewers, merge_request: merge_request)
  end
end
