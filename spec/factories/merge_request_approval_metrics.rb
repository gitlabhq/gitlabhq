# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_approval_metrics, class: "MergeRequest::ApprovalMetrics" do
    merge_request
    last_approved_at { Time.current }
    target_project { merge_request.target_project }
  end
end
