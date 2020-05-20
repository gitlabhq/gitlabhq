# frozen_string_literal: true

FactoryBot.define do
  # TODO: we can remove this factory in favour of :ci_pipeline
  factory :ci_empty_pipeline, class: 'Ci::Pipeline' do
    source { :push }
    ref { 'master' }
    sha { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
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
        status { :failed }
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

      trait :with_test_reports_attachment do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :test_reports_with_attachment, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_broken_test_reports do
        status { :success }

        after(:build) do |pipeline, _evaluator|
          pipeline.builds << build(:ci_build, :broken_test_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_accessibility_reports do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :accessibility_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_coverage_reports do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :coverage_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_terraform_reports do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :terraform_reports, pipeline: pipeline, project: pipeline.project)
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

      trait :detached_merge_request_pipeline do
        merge_request

        source { :merge_request_event }
        project { merge_request.source_project }
        sha { merge_request.source_branch_sha }
        ref { merge_request.ref_path }
      end

      trait :legacy_detached_merge_request_pipeline do
        detached_merge_request_pipeline

        ref { merge_request.source_branch }
      end

      trait :merged_result_pipeline do
        detached_merge_request_pipeline

        sha { 'test-merge-sha'}
        ref { merge_request.merge_ref_path }
        source_sha { merge_request.source_branch_sha }
        target_sha { merge_request.target_branch_sha }
      end
    end
  end
end
