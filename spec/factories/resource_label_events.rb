# frozen_string_literal: true

FactoryBot.define do
  factory :resource_label_event do
    action :add
    label
    user { issuable&.author || create(:user) }

    after(:build) do |event, evaluator|
      event.issue = create(:issue) unless event.issuable
    end
  end
end
