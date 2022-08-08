# frozen_string_literal: true

namespace :knapsack do
  desc "Run tests with knapsack runner"
  task :rspec, [:rspec_args] do |_, args|
    rspec_args = args[:rspec_args]&.split(' ') || []

    unless QA::Runtime::Env.knapsack?
      QA::Runtime::Logger.info("This environment is not compatible with parallel knapsack execution!")
      QA::Runtime::Logger.info("Falling back to standard execution")

      exit RSpec::Core::Runner.run([*rspec_args, "qa/specs/features"])
    end

    exit QA::Specs::KnapsackRunner.run(rspec_args)
  end

  desc "Download latest knapsack reports for parallel jobs"
  task :download, [:stage_name] do |_, args|
    test_stage_name = args[:stage_name]

    # QA_KNAPSACK_REPORTS remains for changes to be backwards compatible
    # TODO: remove and only use automated detection once changes are merged
    unless ENV["QA_KNAPSACK_REPORTS"] || test_stage_name
      QA::Runtime::Logger.warn("Missing QA_KNAPSACK_REPORTS environment variable or test stage name for autodetection")
      next
    end

    reports = if test_stage_name
                QA::Support::ParallelPipelineJobs
                  .fetch(stage_name: test_stage_name, access_token: ENV["QA_GITLAB_CI_TOKEN"])
                  .map { |job| job.tr(":", "-") }
              else
                ENV["QA_KNAPSACK_REPORTS"].split(",")
              end

    reports.each do |report_name|
      QA::Support::KnapsackReport.new(report_name).download_report
    rescue StandardError => e
      QA::Runtime::Logger.error(e)
    end
  end

  desc "Merge and upload knapsack report"
  task :upload, [:glob] do |_task, args|
    QA::Support::KnapsackReport.upload_report(args[:glob])
  end

  desc "Report long running spec files"
  task :notify_long_running_specs do
    QA::Tools::LongRunningSpecReporter.execute
  end
end
