# frozen_string_literal: true

class AnalyticsMergeRequestEntity < AnalyticsIssueEntity
  expose :state

  expose :url do |object|
    url_to(:namespace_project_merge_request, object)
  end
end
