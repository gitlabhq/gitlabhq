# frozen_string_literal: true

namespace :ci do
  desc "Detect changes and generate e2e test pipelines with dynamically scaled parallel jobs"
  task :generate_e2e_pipelines, [:pipeline_path] do |_, args|
    require_relative "helpers/util"
    require_relative '../../tooling/lib/tooling/events/track_pipeline_events'

    include Task::Helpers::Util
    include QA::Tools::Ci::Helpers

    logger.info("*** Analyzing which E2E tests to execute based on MR changes or Scheduled pipeline ***")

    pipeline_path = args[:pipeline_path] || "tmp"
    run_all_label_present = mr_labels.include?("pipeline:run-all-e2e")
    run_no_tests_label_present = mr_labels.include?("pipeline:skip-e2e")

    if run_all_label_present && run_no_tests_label_present
      raise "cannot have both pipeline:run-all-e2e and pipeline:skip-e2e labels. Please remove one of these labels"
    end

    pipeline_creator = QA::Tools::Ci::PipelineCreator.new(
      [],
      pipeline_path: pipeline_path,
      logger: logger
    )

    if run_no_tests_label_present
      logger.info("Merge request has pipeline:skip-e2e label, e2e test execution will be skipped.")
      next pipeline_creator.create_noop(reason: "no-op run, pipeline:skip-e2e label detected")
    end

    diff = mr_diff
    qa_changes = QA::Tools::Ci::QaChanges.new(diff)
    tests = []

    if diff.empty?
      logger.info("No changed file diff provided, full test suite will be executed")
    else
      noop_pipeline = qa_changes.quarantine_changes? || qa_changes.only_spec_removal?

      if noop_pipeline && !run_all_label_present
        if qa_changes.quarantine_changes?
          logger.info("Merge request contains only quarantine changes, e2e test execution will be skipped!")
          next pipeline_creator.create_noop(reason: "no-op run, only quarantine changes detected in merge request")
        end

        if qa_changes.only_spec_removal?
          logger.info("Merge request contains only e2e spec removal, e2e test execution will be skipped!")
          next pipeline_creator.create_noop(reason: "no-op run, only spec removal detected in merge request")
        end
      end

      feature_flags_changes = QA::Tools::Ci::FfChanges.new(diff).fetch
      # on run-all label or framework changes do not infer specific tests
      run_all_tests = run_all_label_present || qa_changes.framework_changes? || !feature_flags_changes.nil?
      tests = qa_changes.qa_tests unless run_all_tests

      if run_all_label_present
        logger.info("Merge request has pipeline:run-all-e2e label, full test suite will be executed")
      elsif qa_changes.framework_changes? # run all tests when framework changes detected
        logger.info("Merge request contains qa framework changes, full test suite will be executed")
      elsif tests.any?
        logger.info("Following specs were selected for execution: '#{tests}'")
      else
        logger.info("No specific specs to execute detected, full test suite will be executed")
      end
    end

    creator_args = {
      pipeline_path: pipeline_path,
      logger: logger,
      env: { "QA_FEATURE_FLAGS" => feature_flags_changes }
    }

    logger.info("*** Creating E2E test pipeline definitions ***")
    QA::Tools::Ci::PipelineCreator.new(tests, **creator_args).create
    next if run_all_tests
    next unless QA::Runtime::Env.selective_execution_improved_enabled? && !QA::Runtime::Env.mr_targeting_stable_branch?

    pipelines_for_selective_improved = [:test_on_gdk]
    logger.warn("*** Recreating #{pipelines_for_selective_improved} using spec list based on coverage mappings ***")
    tests_from_mapping = qa_changes.qa_tests(from_code_path_mapping: true)

    logger.info("Following specs were selected for execution: '#{tests_from_mapping}'")
    begin
      type_of_mr = if mr_labels.include?("frontend") && mr_labels.include?("backend")
                     "fullstack"
                   elsif mr_labels.include?("backend")
                     "backend"
                   elsif mr_labels.include?("frontend")
                     "frontend"
                   else
                     "other"
                   end

      QA::Tools::Ci::PipelineCreator.new(tests_from_mapping, **creator_args).create(pipelines_for_selective_improved)
      properties = {
        label: tests_from_mapping.nil? || tests_from_mapping.empty? ? 'non-selective' : 'selective',
        value: tests_from_mapping.nil? || tests_from_mapping.empty? ? 0 : tests_from_mapping.count,
        property: type_of_mr
      }
      Tooling::Events::TrackPipelineEvents.new(logger: logger).send_event(
        "e2e_tests_selected_for_execution_gitlab_pipeline",
        **properties
      )
    rescue StandardError => e
      logger.warn("*** Error while creating pipeline with selected specs: #{e.backtrace} ***")
      logger.info("*** Defaulting to running full suite ***")
      QA::Tools::Ci::PipelineCreator.new([], **creator_args).create
    end
  end

  desc "Export test run metrics to influxdb"
  task :export_test_metrics, [:glob] do |_, args|
    raise("Metrics file glob pattern is required") unless args[:glob]

    QA::Tools::Ci::TestMetrics.export(args[:glob])
  end

  desc "Export backend code paths mapping to GCP"
  task :export_code_paths_mapping, [:glob] do |_, args|
    raise("Code paths mapping JSON glob pattern is required") unless args[:glob]

    QA::Tools::Ci::CodePathsMapping.export(args[:glob])
  end

  desc "Export frontend code paths mapping to GCP"
  task :export_frontend_code_paths_mapping, [:glob] do |_, args|
    raise("Code paths mapping JSON glob pattern is required") unless args[:glob]

    filename = File.basename(args[:glob])
    prefix = "#{filename.split('*').first}merged-pipeline"
    QA::Tools::Ci::CodePathsMapping.export(args[:glob], bucket: "code-path-mappings",
      file_name: prefix)
  end
end
