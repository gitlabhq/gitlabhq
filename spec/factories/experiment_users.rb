# frozen_string_literal: true

FactoryBot.define do
  factory :experiment_user do
    experiment
    user
    group_type { :control }
    converted_at { nil }
  end
end
