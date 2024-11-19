# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_assignee do
    assignee { association(:user) }
    merge_request { association(:merge_request) }
  end
end
