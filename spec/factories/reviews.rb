# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    merge_request
    association :project, :repository
    author factory: :user
  end
end
