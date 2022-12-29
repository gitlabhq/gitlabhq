# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_machine, class: 'Ci::RunnerMachine' do
    runner factory: :ci_runner
    machine_xid { "r_#{SecureRandom.hex.slice(0, 10)}" }
  end
end
