# frozen_string_literal: true
# rubocop:disable Rails/RakeEnvironment

require_relative "../qa/tools/reliable_report"

desc "Fetch top most reliable specs"
task :reliable_spec_report, [:run_type, :range, :create_slack_report] do |_task, args|
  report = QA::Tools::ReliableReport.new(args[:run_type] || "package-and-qa", args[:range])

  report.show_top_stable
  report.notify_top_stable if args[:create_slack_report] == 'true'
end

desc "Fetch top most unstable reliable specs"
task :unreliable_spec_report, [:run_type, :range, :create_slack_report] do |_task, args|
  report = QA::Tools::ReliableReport.new(args[:run_type] || "package-and-qa", args[:range])

  report.show_top_unstable
  report.notify_top_unstable if args[:create_slack_report] == 'true'
end
# rubocop:enable Rails/RakeEnvironment
