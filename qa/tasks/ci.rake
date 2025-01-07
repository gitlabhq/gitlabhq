# frozen_string_literal: true

namespace :ci do
  desc "Detect changes and generate e2e test pipelines with dynamically scaled parallel jobs"
  task :generate_e2e_pipelines, [:pipeline_path] do |_, args|
    require_relative "helpers/util"

    include Task::Helpers::Util
    include QA::Tools::Ci::Helpers

    logger.info("*** Analyzing merge request changes*** ")

    pipeline_path = args[:pipeline_path] || "tmp"
    diff = mr_diff
    labels = mr_labels
    run_all_label_present = mr_labels.include?("pipeline:run-all-e2e")
    run_no_tests_label_present = mr_labels.include?("pipeline:skip-e2e")

    if run_all_label_present && run_no_tests_label_present
      raise "cannot have both pipeline:run-all-e2e and pipeline:skip-e2e labels. Please remove one of these labels"
    elsif run_no_tests_label_present
      logger.info("Merge request has pipeline:skip-e2e label, e2e test execution will be skipped.")
      QA::Tools::Ci::PipelineCreator.create_noop(pipeline_path: pipeline_path, logger: logger)
      next
    end

    qa_changes = QA::Tools::Ci::QaChanges.new(diff, labels)
    # skip running tests when only quarantine changes detected
    if qa_changes.quarantine_changes?
      logger.info("Merge request contains only quarantine changes, e2e test execution will be skipped!")
      QA::Tools::Ci::PipelineCreator.create_noop(pipeline_path: pipeline_path, logger: logger)
      next
    end

    # on run-all label or framework changes do not infer specific tests
    tests = run_all_label_present || qa_changes.framework_changes? ? nil : qa_changes.qa_tests

    if run_all_label_present
      logger.info("Merge request has pipeline:run-all-e2e label, full test suite will be executed")
    elsif qa_changes.framework_changes? # run all tests when framework changes detected
      logger.info("Merge request contains qa framework changes, full test suite will be executed")
    elsif tests
      logger.info("Detected following specs to execute: '#{tests}'")
    else
      logger.info("No specific specs to execute detected, running full test suites will be executed")
    end

    feature_flags = QA::Tools::Ci::FfChanges.new(diff).fetch

    logger.info("*** Creating E2E test pipeline definitions ***")
    QA::Tools::Ci::PipelineCreator.new(
      tests&.split(" ") || [],
      pipeline_path: pipeline_path,
      logger: logger,
      env: { "QA_FEATURE_FLAGS" => feature_flags }
    ).create
  end

  desc "Export test run metrics to influxdb"
  task :export_test_metrics, [:glob] do |_, args|
    raise("Metrics file glob pattern is required") unless args[:glob]

    QA::Tools::Ci::TestMetrics.export(args[:glob])
  end

  desc "Export code paths mapping to GCP"
  task :export_code_paths_mapping, [:glob] do |_, args|
    raise("Code paths mapping JSON glob pattern is required") unless args[:glob]

    QA::Tools::Ci::CodePathsMapping.export(args[:glob])
  end
end
