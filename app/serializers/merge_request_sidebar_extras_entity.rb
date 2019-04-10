# frozen_string_literal: true

class MergeRequestSidebarExtrasEntity < IssuableSidebarExtrasEntity
  expose :assignees do |merge_request|
    MergeRequestAssigneeEntity.represent(merge_request.assignees, merge_request: merge_request)
  end
end
