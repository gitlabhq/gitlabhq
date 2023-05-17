# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_machine_build, class: 'Ci::RunnerManagerBuild' do
    build factory: :ci_build, scheduling_type: :dag
    runner_manager factory: :ci_runner_machine
  end
end
