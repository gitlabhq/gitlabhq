# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request, traits: [:has_internal_id] do
    title { generate(:title) }
    association :source_project, :repository, factory: :project
    target_project { source_project }
    author { source_project.creator }

    # $ git log --pretty=oneline feature..master
    # 5937ac0a7beb003549fc5fd26fc247adbce4a52e Add submodule from gitlab.com
    # 570e7b2abdd848b95f2f578043fc23bd6f6fd24d Change some files
    # 6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9 More submodules
    # d14d6c0abdd253381df51a723d58691b2ee1ab08 Remove ds_store files
    # c1acaa58bbcbc3eafe538cb8274ba387047b69f8 Ignore DS files
    #
    # See also RepoHelpers.sample_compare
    #
    source_branch { "master" }
    target_branch { "feature" }

    merge_status { "can_be_merged" }

    trait :draft_merge_request do
      title { generate(:draft_title) }
    end

    trait :jira_title do
      title { generate(:jira_title) }
    end

    trait :jira_description do
      description { generate(:jira_description) }
    end

    trait :jira_branch do
      source_branch { generate(:jira_branch) }
    end

    trait :with_image_diffs do
      source_branch { "add_images_and_changes" }
      target_branch { "master" }
    end

    trait :without_diffs do
      source_branch { "improve/awesome" }
      target_branch { "master" }
    end

    trait :conflict do
      source_branch { "feature_conflict" }
      target_branch { "feature" }
    end

    trait :merged do
      state_id { MergeRequest.available_states[:merged] }
    end

    trait :unprepared do
      prepared_at { nil }
    end

    trait :prepared do
      prepared_at { Time.now }
    end

    trait :with_merged_metrics do
      merged

      transient do
        merged_by { author }
        merged_at { nil }
      end

      after(:build) do |merge_request, evaluator|
        metrics = merge_request.build_metrics
        metrics.merged_at = evaluator.merged_at || 1.week.from_now
        metrics.merged_by = evaluator.merged_by
        metrics.pipeline = create(:ci_empty_pipeline)
      end
    end

    trait :merged_target do
      source_branch { "merged-target" }
      target_branch { "improve/awesome" }
    end

    trait :merged_last_month do
      merged

      after(:build) do |merge_request|
        merge_request.build_metrics.merged_at = 1.month.ago
      end
    end

    trait :closed do
      state_id { MergeRequest.available_states[:closed] }
    end

    trait :closed_last_month do
      closed

      after(:build) do |merge_request|
        merge_request.build_metrics.latest_closed_at = 1.month.ago
      end
    end

    trait :opened do
      state_id { MergeRequest.available_states[:opened] }
    end

    trait :invalid do
      source_branch { "feature_one" }
      target_branch { "feature_two" }
    end

    trait :locked do
      state_id { MergeRequest.available_states[:locked] }
    end

    trait :simple do
      source_branch { "feature" }
      target_branch { "master" }
    end

    trait :rebased do
      source_branch { "markdown" }
      target_branch { "improve/awesome" }
    end

    trait :diverged do
      source_branch { "feature" }
      target_branch { "master" }
    end

    trait :merge_when_pipeline_succeeds do
      auto_merge_enabled { true }
      auto_merge_strategy { AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS }
      merge_user { author }
      merge_params do
        { 'auto_merge_strategy' => AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS, sha: diff_head_sha }
      end
    end

    trait :merge_when_checks_pass do
      auto_merge_enabled { true }
      auto_merge_strategy { AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS }
      merge_user { author }
      merge_params do
        { sha: diff_head_sha, 'auto_merge_strategy' => AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS }
      end
    end

    trait :remove_source_branch do
      merge_params do
        { 'force_remove_source_branch' => '1' }
      end
    end

    trait :with_head_pipeline do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :running,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_test_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_test_reports,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_accessibility_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_accessibility_reports,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_codequality_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_codequality_reports,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :unique_branches do
      source_branch { generate(:branch) }
      target_branch { generate(:branch) }
    end

    trait :unique_author do
      author { association(:user) }
    end

    trait :with_assignee do
      assignees { [author] }
    end

    trait :with_coverage_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_coverage_report_artifact,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_codequality_mr_diff_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_codequality_mr_diff_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_terraform_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_terraform_reports,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_sast_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_sast_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_secret_detection_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_secret_detection_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_exposed_artifacts do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ci_pipeline,
          :success,
          :with_exposed_artifacts,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_legacy_detached_merge_request_pipeline do
      after(:create) do |merge_request|
        create(:ci_pipeline, :legacy_detached_merge_request_pipeline, merge_request: merge_request)
      end
    end

    trait :with_detached_merge_request_pipeline do
      after(:create) do |merge_request|
        create(:ci_pipeline, :detached_merge_request_pipeline, merge_request: merge_request)
      end
    end

    trait :with_merge_request_pipeline do
      transient do
        merge_sha { 'mergesha' }
        source_sha { source_branch_sha }
        target_sha { target_branch_sha }
      end

      after(:create) do |merge_request, evaluator|
        create(:ci_pipeline, :merged_result_pipeline,
          merge_request: merge_request,
          sha: evaluator.merge_sha,
          source_sha: evaluator.source_sha,
          target_sha: evaluator.target_sha
        )
      end
    end

    trait :deployed_review_app do
      target_branch { 'pages-deploy-target' }

      transient do
        deployment { association(:deployment, :review_app) }
      end

      after(:build) do |merge_request, evaluator|
        merge_request.source_branch = evaluator.deployment.ref
        merge_request.source_project = evaluator.deployment.project
        merge_request.target_project = evaluator.deployment.project
      end
    end

    trait :sequence_source_branch do
      sequence(:source_branch) { |n| "feature#{n}" }
    end

    trait :skip_diff_creation do
      before(:create) do |merge_request, _|
        merge_request.skip_ensure_merge_request_diff = true
      end
    end

    after(:build) do |merge_request|
      target_project = merge_request.target_project
      source_project = merge_request.source_project

      # Fake `fetch_ref!` if we don't have repository
      # We have too many existing tests relying on this behaviour
      unless [target_project, source_project].all?(&:repository_exists?)
        stub_method(merge_request, :fetch_ref!) { nil }
      end
    end

    after(:build) do |merge_request, evaluator|
      merge_request.state_id = MergeRequest.available_states[evaluator.state]
    end

    after(:create) do |merge_request, evaluator|
      merge_request.cache_merge_request_closes_issues!
    end

    factory :merged_merge_request, traits: [:merged]
    factory :closed_merge_request, traits: [:closed]
    factory :reopened_merge_request, traits: [:opened]
    factory :invalid_merge_request, traits: [:invalid]
    factory :merge_request_with_diffs
    factory :merge_request_with_diff_notes do
      after(:create) do |mr|
        create(:diff_note_on_merge_request, noteable: mr, project: mr.source_project)
      end
    end
    factory :merge_request_with_multiple_diffs do
      after(:create) do |mr|
        mr.merge_request_diffs.create!(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
      end
    end

    factory :labeled_merge_request do
      transient do
        labels { [] }
      end

      after(:create) do |merge_request, evaluator|
        merge_request.update!(labels: evaluator.labels)
      end
    end
  end
end
