# frozen_string_literal: true

FactoryBot.define do
  factory :ci_processable, class: 'Ci::Processable' do
    name { 'processable' }
    stage_idx { ci_stage.try(:position) || 0 }
    ref { 'master' }
    tag { false }
    pipeline factory: :ci_pipeline
    project { pipeline.project }
    scheduling_type { 'stage' }
    partition_id { pipeline.partition_id }

    options do
      {}
    end

    # This factory was updated to help with the efforts of the removal of `ci_builds.stage`:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/364377
    # These blocks can be updated once all instances of `stage` are removed from the spec files:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/467212

    transient do
      stage { 'test' }
    end

    after(:build) do |processable, evaluator|
      next if processable.ci_stage

      pipeline = processable.pipeline

      existing_stage =
        if pipeline.respond_to?(:reload) && pipeline.persisted?
          pipeline.reload.stages.find_by(name: evaluator.stage)
        else
          pipeline.stages.find { |stage| stage.name == evaluator.stage }
        end

      if existing_stage.present?
        processable.ci_stage = existing_stage

        next
      end

      new_stage = build(
        :ci_stage,
        pipeline: processable.pipeline,
        project: processable.project || evaluator.project,
        name: evaluator.stage,
        position: evaluator.stage_idx,
        status: 'created'
      )

      pipeline.stages << new_stage
      processable.ci_stage = new_stage
    end

    before(:create) do |processable, evaluator|
      next if processable.ci_stage

      processable.ci_stage =
        if ci_stage = processable.pipeline.stages.find_by(name: evaluator.stage)
          ci_stage
        else
          create(
            :ci_stage,
            pipeline: processable.pipeline,
            project: processable.project || evaluator.project,
            name: evaluator.stage,
            position: evaluator.stage_idx,
            status: 'created'
          )
        end
    end

    trait :waiting_for_resource do
      status { 'waiting_for_resource' }
    end

    trait :resource_group do
      waiting_for_resource_at { 5.minutes.ago }

      after(:build) do |processable, evaluator|
        processable.resource_group = create(:ci_resource_group, project: processable.project)
      end
    end

    trait :interruptible do
      after(:build) do |processable|
        processable.metadata.interruptible = true
      end
    end
  end
end
