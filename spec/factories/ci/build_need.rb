# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_need, class: Ci::BuildNeed do
    build factory: :ci_build
    sequence(:name) { |n| "build_#{n}" }
  end
end
