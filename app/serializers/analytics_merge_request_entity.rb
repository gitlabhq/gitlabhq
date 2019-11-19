# frozen_string_literal: true

class AnalyticsMergeRequestEntity < AnalyticsIssueEntity
  expose :state do |object|
    MergeRequest.available_states.key(object[:state_id])
  end

  expose :url do |object|
    url_to(:namespace_project_merge_request, object)
  end
end
