# frozen_string_literal: true

class MergeRequestSidebarExtrasEntity < IssuableSidebarExtrasEntity
  expose :assignees do |merge_request, options|
    MergeRequestUserEntity.represent(merge_request.assignees, options.merge(merge_request: merge_request, type: :assignees))
  end

  expose :reviewers do |merge_request, options|
    MergeRequestUserEntity.represent(merge_request.reviewers, options.merge(merge_request: merge_request, type: :reviewers))
  end
end
