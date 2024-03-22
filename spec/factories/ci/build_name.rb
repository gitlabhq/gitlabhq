# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_name, class: 'Ci::BuildName' do
    build factory: :ci_build, scheduling_type: :dag
    project_id { build.project_id }
    name { build.name }
  end
end
