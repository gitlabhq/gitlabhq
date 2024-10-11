# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_machine, class: 'Ci::RunnerManager' do
    runner factory: :ci_runner
    system_xid { "r_#{SecureRandom.hex.slice(0, 10)}" }

    creation_state { :finished }

    after(:build) do |runner_manager, evaluator|
      runner_manager.runner_type ||= evaluator.runner.runner_type
      runner_manager.sharding_key_id ||= evaluator.runner.sharding_key_id
    end

    trait :unregistered do
      contacted_at { nil }
      creation_state { :started }
    end

    trait :online do
      contacted_at { Time.current }
    end

    trait :almost_offline do
      contacted_at { 0.001.seconds.after(Ci::RunnerManager.online_contact_time_deadline) }
    end

    trait :offline do
      contacted_at { Ci::RunnerManager.online_contact_time_deadline }
    end

    trait :stale do
      after(:build) do |runner_manager, evaluator|
        if evaluator.uncached_contacted_at.nil? && evaluator.creation_state == :finished
          # Set stale contacted_at value unless this is an `:unregistered` runner manager
          runner_manager.contacted_at = Ci::Runner.stale_deadline
        end

        runner_manager.created_at = [
          runner_manager.created_at, runner_manager.uncached_contacted_at, Ci::Runner.stale_deadline
        ].compact.min
      end
    end

    trait :created_within_stale_deadline do
      created_at { 0.001.seconds.after(Ci::RunnerManager.stale_deadline) }
    end
  end
end
