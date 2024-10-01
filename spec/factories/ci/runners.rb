# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner, class: 'Ci::Runner' do
    sequence(:description) { |n| "My runner#{n}" }

    active { true }
    access_level { :not_protected }

    runner_type { :instance_type }

    creation_state { :finished }

    transient do
      groups { [] }
      projects { [] }
      token_expires_at { nil }
      creator { nil }
      without_projects { false }
    end

    after(:build) do |runner, evaluator|
      runner.sharding_key_id ||= evaluator.projects.first&.id if runner.project_type?
      evaluator.projects.each do |proj|
        runner.runner_projects << build(:ci_runner_project, runner: runner, project: proj)
      end

      runner.sharding_key_id ||= evaluator.groups.first&.id if runner.group_type?
      evaluator.groups.each do |group|
        runner.runner_namespaces << build(:ci_runner_namespace, runner: runner, namespace: group)
      end

      runner.creator = evaluator.creator if evaluator.creator

      case runner.runner_type
      when 'group_type'
        raise ':groups is mandatory' unless evaluator.groups&.any?
      when 'project_type'
        raise ':projects is mandatory' unless evaluator.projects&.any? || evaluator.without_projects
      end
    end

    after(:create) do |runner, evaluator|
      runner.update!(token_expires_at: evaluator.token_expires_at) if evaluator.token_expires_at
    end

    trait :unregistered do
      contacted_at { nil }
      creation_state { :started }
    end

    trait :online do
      contacted_at { Time.current }
    end

    trait :almost_offline do
      contacted_at { 0.001.seconds.after(Ci::Runner.online_contact_time_deadline) }
    end

    trait :offline do
      contacted_at { Ci::Runner.online_contact_time_deadline }
    end

    trait :stale do
      after(:build) do |runner, evaluator|
        if evaluator.uncached_contacted_at.nil? && evaluator.creation_state == :finished
          # Set stale contacted_at value unless this is an `:unregistered` runner
          runner.contacted_at = Ci::Runner.stale_deadline
        end

        runner.created_at = [runner.created_at, runner.uncached_contacted_at, Ci::Runner.stale_deadline].compact.min
      end
    end

    trait :contacted_within_stale_deadline do
      contacted_at { 0.001.seconds.after(Ci::Runner.stale_deadline) }
    end

    trait :created_within_stale_deadline do
      created_at { 0.001.seconds.after(Ci::Runner.stale_deadline) }
    end

    trait :instance do
      runner_type { :instance_type }
    end

    trait :group do
      runner_type { :group_type }

      after(:build) do |runner, evaluator|
        if runner.runner_namespaces.empty?
          runner.runner_namespaces << build(:ci_runner_namespace, runner: runner)
        end
      end
    end

    trait :project do
      runner_type { :project_type }

      after(:build) do |runner, evaluator|
        if runner.runner_projects.empty?
          runner.runner_projects << build(:ci_runner_project, runner: runner)
        end
      end
    end

    # we use without_projects to create invalid runner: the one without projects
    trait :without_projects do
      transient do
        without_projects { true }
      end

      after(:build) do |runner, evaluator|
        next if runner.sharding_key_id

        # Point to a "no longer existing" project ID, as a project runner must always have been created
        # with a sharding key id
        runner.sharding_key_id = (2**63) - 1
      end

      after(:create) do |runner, evaluator|
        runner.runner_projects.delete_all
      end
    end

    trait :with_runner_manager do
      after(:build) do |runner, evaluator|
        runner.runner_managers << build(:ci_runner_machine, runner: runner)
      end
    end

    trait :paused do
      active { false }
    end

    trait :ref_protected do
      access_level { :ref_protected }
    end

    trait :tagged_only do
      run_untagged { false }

      tag_list { %w[tag1 tag2] }
    end

    trait :locked do
      locked { true }
    end
  end
end
