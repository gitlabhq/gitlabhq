# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_transition, class: 'WorkItems::Transition' do
    trait :moved do
      association :moved_to
    end

    trait :promoted do
      association :promoted_to_epic
    end

    trait :duplicated do
      association :duplicated_to
    end
  end
end
