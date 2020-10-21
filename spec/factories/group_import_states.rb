# frozen_string_literal: true

FactoryBot.define do
  factory :group_import_state, class: 'GroupImportState', traits: %i[created] do
    association :group, factory: :group
    association :user, factory: :user

    trait :created do
      status { 0 }
    end

    trait :started do
      status { 1 }
      sequence(:jid) { |n| "group_import_state_#{n}" }
    end

    trait :finished do
      status { 2 }
      sequence(:jid) { |n| "group_import_state_#{n}" }
    end

    trait :failed do
      status { -1 }
    end
  end
end
