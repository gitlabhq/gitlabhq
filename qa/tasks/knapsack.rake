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
    knapsack_reports = ENV["QA_KNAPSACK_REPORTS"]&.split(",")
    ci_token = ENV["QA_GITLAB_CI_TOKEN"]
    QA::Support::KnapsackReport.configure!

    reports = if knapsack_reports
                knapsack_reports
              else
                unless ci_token
                  QA::Runtime::Logger.error("Missing QA_GITLAB_CI_TOKEN for automatically detecting parallel jobs")
                  next
                end

                QA::Support::ParallelPipelineJobs
                  .fetch(stage_name: test_stage_name, access_token: ci_token)
                  .map { |job| job.tr(":", "-") }
              end

    reports.each do |report_name|
      QA::Support::KnapsackReport.new(report_name).download_report
    rescue StandardError => e
      QA::Runtime::Logger.error(e)
    end
  end

  desc "Merge and upload knapsack report"
  task :upload, [:glob] do |_task, args|
    QA::Support::KnapsackReport.configure!
    QA::Support::KnapsackReport.upload_report(args[:glob])
  end

  desc "Report long running spec files"
  task :notify_long_running_specs do
    QA::Tools::LongRunningSpecReporter.execute
  end
end
