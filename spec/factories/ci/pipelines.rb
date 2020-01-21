# frozen_string_literal: true

FactoryBot.define do
  # TODO: we can remove this factory in favour of :ci_pipeline
  factory :ci_empty_pipeline, class: 'Ci::Pipeline' do
    source { :push }
    ref { 'master' }
    sha { '97de212e80737a608d939f648d959671fb0a0142' }
    status { 'pending' }
    add_attribute(:protected) { false }

    project

    # Persist merge request head_pipeline_id
    # on pipeline factories to avoid circular references
    transient { head_pipeline_of { nil } }

    after(:create) do |pipeline, evaluator|
      merge_request = evaluator.head_pipeline_of
      merge_request&.update(head_pipeline: pipeline)
    end

    factory :ci_pipeline do
      trait :invalid do
        yaml_errors { 'invalid YAML' }
        failure_reason { :config_error }
      end

      trait :created do
        status { :created }
      end

      trait :preparing do
        status { :preparing }
      end

      trait :blocked do
        status { :manual }
      end

      trait :scheduled do
        status { :scheduled }
      end

      trait :success do
        status { :success }
      end

      trait :running do
        status { :running }
      end

      trait :failed do
        status { :failed }
      end

      trait :protected do
        add_attribute(:protected) { true }
      end

      trait :with_test_reports do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :test_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_exposed_artifacts do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :artifacts,
            pipeline: pipeline,
            project: pipeline.project,
            options: { artifacts: { expose_as: 'the artifact', paths: ['ci_artifacts.txt'] } })
        end
      end

      trait :with_job do
        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :auto_devops_source do
        config_source { Ci::Pipeline.config_sources[:auto_devops_source] }
      end

      trait :repository_source do
        config_source { Ci::Pipeline.config_sources[:repository_source] }
      end
    end
  end
end
