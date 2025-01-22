# frozen_string_literal: true

FactoryBot.define do
  factory :issue_user_mention do
    association :issue
    association :note
  end
end
