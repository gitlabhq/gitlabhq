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

    noop_pipeline_creator = QA::Tools::Ci::PipelineCreator.new(
      [],
      pipeline_path: pipeline_path,
      logger: logger
    )

    if run_no_tests_label_present
      logger.info("Merge request has pipeline:skip-e2e label, e2e test execution will be skipped.")
      next noop_pipeline_creator.create_noop(reason: "no-op run, pipeline:skip-e2e label detected")
    end

    diff = mr_diff
    changes = QA::Tools::Ci::QaChanges.new(diff)
    tests = []

    if diff.empty?
      logger.info("No changed file diff provided, full test suite will be executed")
    else
      noop = changes.quarantine_changes? || changes.only_spec_removal? || changes.only_changes_to_non_e2e_spec_files?

      if noop && !run_all_label_present
        msg_prefix = "Skipping e2e test execution because"

        if changes.quarantine_changes?
          logger.info("#{msg_prefix} only quarantine changes detected in merge request!")
          next noop_pipeline_creator.create_noop(reason: "#{msg_prefix}, quarantine changes detected in merge request")
        end

        if changes.only_spec_removal?
          logger.info("#{msg_prefix} only e2e spec removal detected in merge request!")
          next noop_pipeline_creator.create_noop(reason: "#{msg_prefix} e2e spec removal detected in merge request")
        end

        if changes.only_changes_to_non_e2e_spec_files?
          logger.info("#{msg_prefix} only non e2e test changes detected in merge request!")
          next noop_pipeline_creator.create_noop(reason: "#{msg_prefix} non e2e test changes detected in merge request")
        end
      end

      feature_flags_changes = QA::Tools::Ci::FfChanges.new(diff).fetch
      # on run-all label or framework changes do not infer specific tests
      run_all_tests = run_all_label_present || changes.framework_changes? || !feature_flags_changes.nil?
      tests = changes.qa_tests unless run_all_tests

      if run_all_label_present
        logger.info("Merge request has pipeline:run-all-e2e label, full test suite will be executed")
      elsif changes.framework_changes? # run all tests when framework changes detected
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
    pipeline_creator = QA::Tools::Ci::PipelineCreator.new(tests, **creator_args)

    logger.info("*** Creating Functional E2E test pipeline definitions ***")
    pipeline_creator.create
    logger.info("*** Creating Non-Functional E2E test pipeline definitions ***")
    pipeline_creator.create_non_functional
    next if run_all_tests
    next unless QA::Runtime::Env.selective_execution_improved_enabled? && !QA::Runtime::Env.mr_targeting_stable_branch?

    pipelines_for_selective_improved = [:test_on_gdk]
    logger.warn("*** Recreating #{pipelines_for_selective_improved} using spec list based on coverage mappings ***")
    tests_from_mapping = changes.qa_tests(from_code_path_mapping: true)

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
