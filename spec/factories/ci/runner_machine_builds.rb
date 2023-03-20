# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_machine_build, class: 'Ci::RunnerMachineBuild' do
    build factory: :ci_build, scheduling_type: :dag
    runner_machine factory: :ci_runner_machine
  end
end
