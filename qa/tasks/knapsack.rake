# frozen_string_literal: true

# rubocop:disable Rails/RakeEnvironment
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

  desc "Download latest knapsack report or multiple reports passed via QA_KNAPSACK_REPORTS env variable"
  task :download do
    next QA::Support::KnapsackReport.download_report unless ENV["QA_KNAPSACK_REPORTS"]

    ENV["QA_KNAPSACK_REPORTS"].split(",").each do |report_name|
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
# rubocop:enable Rails/RakeEnvironment
