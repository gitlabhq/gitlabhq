# frozen_string_literal: true
# rubocop:disable Rails/RakeEnvironment

require_relative "../qa/tools/knapsack_report"

namespace :knapsack do
  desc "Download latest knapsack report"
  task :download do
    QA::Tools::KnapsackReport.download
  end

  desc "Merge and upload knapsack report"
  task :upload, [:glob_pattern] do |_task, args|
    QA::Tools::KnapsackReport.upload(args[:glob_pattern])
  end
end
# rubocop:enable Rails/RakeEnvironment
