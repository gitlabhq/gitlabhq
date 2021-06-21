# frozen_string_literal: true

FactoryBot.define do
  factory :ci_running_build, class: 'Ci::RunningBuild' do
    build factory: :ci_build
    project
    runner factory: :ci_runner
    runner_type { runner.runner_type }
  end
end
