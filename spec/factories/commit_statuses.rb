# frozen_string_literal: true

FactoryBot.define do
  factory :commit_status, class: 'CommitStatus' do
    name { 'default' }
    stage_idx { 0 }
    status { 'success' }
    description { 'commit status' }
    pipeline factory: :ci_pipeline
    started_at { 'Tue, 26 Jan 2016 08:21:42 +0100' }
    finished_at { 'Tue, 26 Jan 2016 08:23:42 +0100' }
    partition_id { pipeline&.partition_id }

    transient do
      stage { 'test' }
    end

    before(:create) do |commit_status, evaluator|
      next if commit_status.ci_stage

      ci_stage = commit_status.pipeline.stages.find_by(name: evaluator.stage)

      commit_status.ci_stage =
        # rubocop: disable RSpec/FactoryBot/StrategyInCallback -- we need to create ci_stages if there aren't any
        (ci_stage.presence || create(
          :ci_stage,
          pipeline: commit_status.pipeline,
          project: commit_status.project || evaluator.project,
          name: evaluator.stage,
          position: evaluator.stage_idx,
          status: 'created'
        ))
      # rubocop: enable RSpec/FactoryBot/StrategyInCallback
    end

    trait :success do
      status { 'success' }
    end

    trait :failed do
      status { 'failed' }
    end

    trait :canceling do
      status { 'canceling' }
    end

    trait :canceled do
      status { 'canceled' }
    end

    trait :skipped do
      status { 'skipped' }
    end

    trait :running do
      status { 'running' }
    end

    trait :waiting_for_callback do
      status { 'waiting_for_callback' }
    end

    trait :pending do
      status { 'pending' }
    end

    trait :waiting_for_resource do
      status { 'waiting_for_resource' }
    end

    trait :preparing do
      status { 'preparing' }
    end

    trait :created do
      status { 'created' }
    end

    trait :manual do
      status { 'manual' }
    end

    trait :scheduled do
      status { 'scheduled' }
    end

    after(:build) do |build, evaluator|
      build.project ||= build.pipeline.project
    end
  end
end
