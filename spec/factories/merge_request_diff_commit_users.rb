# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_diff_commit_user, class: 'MergeRequest::DiffCommitUser' do
    name { generate(:name) }
    email { generate(:email) }
  end
end
