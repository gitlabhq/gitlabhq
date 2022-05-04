# frozen_string_literal: true

namespace :knapsack do
  desc "Run tests with knapsack runner"
  task :rspec, [:rspec_args] do |_, args|
    unless QA::Runtime::Env.knapsack?
      QA::Runtime::Logger.info("This environment is not compatible with parallel knapsack execution!")
      QA::Runtime::Logger.info("Falling back to standard execution")

      exec(%Q[bundle exec rspec #{args[:rspec_args]}])
    end

    QA::Support::KnapsackReport.configure!
    Knapsack::Runners::RSpecRunner.run(args[:rspec_args])
  end

  desc "Download latest knapsack report"
  task :download do
    QA::Support::KnapsackReport.download
  end

  desc "Merge and upload knapsack report"
  task :upload, [:glob] do |_task, args|
    QA::Support::KnapsackReport.upload_report(args[:glob])
  end

  desc "Report long running spec files"
  task :notify_long_running_specs do
    QA::Support::LongRunningSpecReporter.execute
  end
end
