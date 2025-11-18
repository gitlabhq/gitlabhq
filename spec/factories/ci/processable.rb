# frozen_string_literal: true

require Rails.root.join('spec/support/helpers/ci/job_factory_helpers')

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

    # This factory was updated to help with the efforts of the removal of `ci_builds.stage`:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/364377
    # These blocks can be updated once all instances of `stage` are removed from the spec files:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/467212

    transient do
      options { {} }
      yaml_variables { [] }
      stage { 'test' }
    end

    after(:stub, :build) do |processable, evaluator|
      Ci::JobFactoryHelpers.mutate_temp_job_definition(
        processable, options: evaluator.options, yaml_variables: evaluator.yaml_variables)
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
      if processable.temp_job_definition
        Gitlab::Ci::Pipeline::Create::JobDefinitionBuilder.new(processable.pipeline, [processable]).run
      end

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

    after(:create) do |processable, evaluator|
      # job_definition_instance is assigned when we run JobDefinitionBuilder
      next unless processable.job_definition_instance

      processable.association(:job_definition).reload
      processable.temp_job_definition = nil
    end

    trait :without_job_definition do
      after(:build) do |processable, evaluator|
        processable.temp_job_definition = nil
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
        Ci::JobFactoryHelpers.mutate_temp_job_definition(processable, interruptible: true)
      end
    end
  end
end
