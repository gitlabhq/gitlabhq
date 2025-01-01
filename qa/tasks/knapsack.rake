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

  desc "Create and upload custom report for all tests in pipeline"
  task :upload_example_runtimes, [:glob] do |_task, args|
    QA::Support::KnapsackReport.upload_example_runtimes(args[:glob])
  end

  desc "Report long running spec files"
  task :notify_long_running_specs do
    QA::Tools::LongRunningSpecReporter.execute
  end

  desc "Update fallback knapsack report"
  task :update_fallback_report do
    QA::Tools::KnapsackReportUpdater.run
  end
end
