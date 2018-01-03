FactoryBot.define do
  factory :commit_status, class: CommitStatus do
    name 'default'
    stage 'test'
    status 'success'
    description 'commit status'
    pipeline factory: :ci_pipeline_with_one_job
    started_at 'Tue, 26 Jan 2016 08:21:42 +0100'
    finished_at 'Tue, 26 Jan 2016 08:23:42 +0100'

    trait :success do
      status 'success'
    end

    trait :failed do
      status 'failed'
    end

    trait :canceled do
      status 'canceled'
    end

    trait :skipped do
      status 'skipped'
    end

    trait :running do
      status 'running'
    end

    trait :pending do
      status 'pending'
    end

    trait :created do
      status 'created'
    end

    trait :manual do
      status 'manual'
    end

    after(:build) do |build, evaluator|
      build.project = build.pipeline.project
    end

    factory :generic_commit_status, class: GenericCommitStatus do
      name 'generic'
      description 'external commit status'
    end
  end
end
