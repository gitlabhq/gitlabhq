# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_need, class: 'Ci::BuildNeed' do
    build factory: :ci_build, scheduling_type: :dag
    sequence(:name) { |n| "build_#{n}" }
    project_id { build.project.id }
  end
end
