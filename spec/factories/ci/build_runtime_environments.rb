# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_runtime_environment, class: 'Ci::BuildRuntimeEnvironment' do
    build factory: :ci_build, scheduling_type: :dag
    project_id { build.project_id }
    runtime_environment factory: :ci_runtime_environment
  end
end
