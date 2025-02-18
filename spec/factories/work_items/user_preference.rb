# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_user_preference, class: 'WorkItems::UserPreference' do
    association :user
    association :namespace
    association :work_item_type
  end
end
