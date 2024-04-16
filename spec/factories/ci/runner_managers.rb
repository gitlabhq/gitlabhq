# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_machine, class: 'Ci::RunnerManager' do
    runner factory: :ci_runner
    system_xid { "r_#{SecureRandom.hex.slice(0, 10)}" }

    creation_state { :finished }

    trait :unregistered do
      contacted_at { nil }
      creation_state { :started }
    end

    trait :stale do
      created_at { 1.year.ago }
      contacted_at { Ci::RunnerManager::STALE_TIMEOUT.ago }
    end
  end
end
