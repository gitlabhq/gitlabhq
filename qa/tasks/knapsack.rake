# frozen_string_literal: true
# rubocop:disable Rails/RakeEnvironment

require_relative "../qa/tools/knapsack_report"

namespace :knapsack do
  desc "Download latest knapsack report"
  task :download do
    QA::Tools::KnapsackReport.download
  end

  desc "Merge and upload knapsack report"
  task :upload, [:glob] do |_task, args|
    QA::Tools::KnapsackReport.upload_report(args[:glob])
  end
end
# rubocop:enable Rails/RakeEnvironment
