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
      token { nil }
      token_expires_at { nil }
      creator { nil }
      without_projects { false }
    end

    organization_id { (projects.first || groups.first)&.organization_id }

    # Build (not create) the join records so they are autosaved together with the runner.
    runner_projects do
      projects.map { |project| association(:ci_runner_project, strategy: :build, runner: instance, project: project) }
    end

    runner_namespaces do
      groups.map { |group| association(:ci_runner_namespace, strategy: :build, runner: instance, namespace: group) }
    end

    after(:build) do |runner, evaluator|
      runner.creator = evaluator.creator if evaluator.creator

      runner.set_token(evaluator.token) if evaluator.token

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

    trait :created_before_registration_deadline do
      created_at { 0.001.seconds.after(Ci::Runner::REGISTRATION_AVAILABILITY_TIME.ago) }
    end

    trait :created_after_registration_deadline do
      created_at { Ci::Runner::REGISTRATION_AVAILABILITY_TIME.ago }
    end

    trait :instance do
      runner_type { :instance_type }
    end

    trait :group do
      runner_type { :group_type }
    end

    trait :project do
      runner_type { :project_type }
    end

    # we use without_projects to create invalid runner: the one without projects
    trait :without_projects do
      transient do
        without_projects { true }
      end

      organization_id { association(:common_organization, strategy: :create).id }

      # Tolerate only the missing project instead of creating a throwaway one, so other validation errors still raise.
      to_create do |runner|
        runner.validate
        runner.errors.delete(:runner, Ci::Runner::NO_PROJECTS_ERROR_MESSAGE)
        raise ActiveRecord::RecordInvalid, runner if runner.errors.any?

        runner.save!(validate: false)
      end

      after(:create) do |runner, _evaluator|
        runner.clear_memoization(:owner)
      end
    end

    trait :with_runner_manager do
      runner_managers { [association(:ci_runner_machine, strategy: :build, runner: instance)] }
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

    trait :hosted_runner do
      creator { Users::Internal.in_organization(organization_id).admin_bot }
    end

    trait :with_future_rotation_deadline do
      token_rotation_deadline { 1.hour.from_now }
    end

    trait :with_past_rotation_deadline do
      token_rotation_deadline { 1.minute.ago }
    end
  end
end
