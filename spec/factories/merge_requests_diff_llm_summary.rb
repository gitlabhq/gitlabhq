# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff_llm_summary, class: 'MergeRequest::DiffLlmSummary' do
    association :user, factory: :user
    association :merge_request_diff, factory: :merge_request_diff
    provider { 0 }
    content { 'test' }
  end
end
