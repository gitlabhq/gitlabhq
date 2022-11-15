# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_reviewer do
    merge_request
    reviewer { association(:user) }
    state { 'unreviewed' }
  end
end
