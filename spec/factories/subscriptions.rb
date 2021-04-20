# frozen_string_literal: true

FactoryBot.define do
  factory :subscription do
    project
    user { project.creator }
    subscribable factory: :issue

    trait :group_label do
      project { nil }
      user { association(:user) }
      subscribable factory: :group_label
    end
  end
end
