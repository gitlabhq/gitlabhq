# frozen_string_literal: true

FactoryBot.define do
  # TODO: we can remove this factory in favour of :ci_pipeline
  factory :ci_empty_pipeline, class: 'Ci::Pipeline' do
    source { :push }
    ref { 'master' }
    sha { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    status { 'pending' }
    add_attribute(:protected) { false }
    partition_id { Ci::Pipeline.current_partition_value }

    project

    # Persist merge request head_pipeline_id
    # on pipeline factories to avoid circular references
    transient { head_pipeline_of { nil } }

    transient { child_of { nil } }
    transient { upstream_of { nil } }

    transient { name { nil } }

    transient { ci_ref_presence { true } }

    before(:create) do |pipeline, evaluator|
      pipeline.ensure_ci_ref! if evaluator.ci_ref_presence && pipeline.ci_ref_id.nil?
    end

    after(:build) do |pipeline, evaluator|
      if evaluator.child_of
        pipeline.project = evaluator.child_of.project
        pipeline.source = :parent_pipeline
      end

      pipeline.ensure_project_iid!

      if evaluator.name
        pipeline.pipeline_metadata = build(:ci_pipeline_metadata, name: evaluator.name, project: pipeline.project, pipeline: pipeline)
      end
    end

    after(:create) do |pipeline, evaluator|
      merge_request = evaluator.head_pipeline_of
      merge_request&.update!(head_pipeline: pipeline)

      if evaluator.child_of
        bridge = create(:ci_bridge, pipeline: evaluator.child_of)
        create(:ci_sources_pipeline, source_job: bridge, pipeline: pipeline)
      end

      if evaluator.upstream_of
        bridge = create(:ci_bridge, pipeline: pipeline)
        create(:ci_sources_pipeline, source_job: bridge, pipeline: evaluator.upstream_of)
      end
    end

    trait :created do
      status { :created }
    end

    factory :ci_pipeline do
      trait :invalid do
        status { :failed }
        # TODO: This trait will be removed soon. Please use `invalid_config_error`. If an error message is necessary,
        # use pipeline.add_error_message
        # https://gitlab.com/gitlab-org/gitlab/-/issues/516915
        yaml_errors { 'invalid YAML' }
        failure_reason { :config_error }
      end

      trait :invalid_config_error do
        status { :failed }
        failure_reason { :config_error }
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

      trait :manual do
        status { :manual }
      end

      trait :running do
        started_at { Time.current }
        status { :running }
      end

      trait :pending do
        status { :pending }
      end

      trait :canceled do
        status { :canceled }
      end

      trait :failed do
        status { :failed }
      end

      trait :skipped do
        status { :skipped }
      end

      trait :unlocked do
        locked { Ci::Pipeline.lockeds[:unlocked] }
      end

      trait :artifacts_locked do
        locked { Ci::Pipeline.lockeds[:artifacts_locked] }
      end

      trait :protected do
        add_attribute(:protected) { true }
      end

      trait :with_report_results do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :report_results, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_codequality_report do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :codequality_report, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_sast_report do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :sast_report, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_secret_detection_report do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :secret_detection_report, pipeline: pipeline, project: pipeline.project)
        end
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

      trait :with_test_reports_with_three_failures do
        status { :failed }

        after(:build) do |pipeline, _evaluator|
          pipeline.builds << build(:ci_build, :failed, :test_reports_with_three_failures, pipeline: pipeline, project: pipeline.project)
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

      trait :with_codequality_reports do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :codequality_reports, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_coverage_report_artifact do
        after(:build) do |pipeline, evaluator|
          pipeline.pipeline_artifacts << build(:ci_pipeline_artifact, :with_coverage_report, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_codequality_mr_diff_report do
        after(:build) do |pipeline, evaluator|
          pipeline.pipeline_artifacts << build(:ci_pipeline_artifact, :with_codequality_mr_diff_report, pipeline: pipeline, project: pipeline.project)
        end
      end

      trait :with_terraform_reports do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ci_build, :terraform_reports, pipeline: pipeline, project: pipeline.project)
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

      trait :with_persisted_artifacts do
        status { :success }

        after(:create) do |pipeline, evaluator|
          pipeline.builds << create(:ci_build, :artifacts, pipeline: pipeline, project: pipeline.project)
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

        sha { 'mergeSha' }
        ref { merge_request.merge_ref_path }
        source_sha { merge_request.source_branch_sha }
        target_sha { merge_request.target_branch_sha }
      end

      trait :webide do
        source { :webide }
        config_source { :webide_source }
      end
    end
  end
end
