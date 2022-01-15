# frozen_string_literal: true
# rubocop:disable Rails/RakeEnvironment

namespace :knapsack do
  desc "Download latest knapsack report"
  task :download do
    QA::Tools::KnapsackReport.download
  end

  desc "Merge and upload knapsack report"
  task :upload, [:glob] do |_task, args|
    QA::Tools::KnapsackReport.upload_report(args[:glob])
  end

  desc "Report long running spec files"
  task :notify_long_running_specs do
    QA::Tools::LongRunningSpecReporter.execute
  end
end
# rubocop:enable Rails/RakeEnvironment
