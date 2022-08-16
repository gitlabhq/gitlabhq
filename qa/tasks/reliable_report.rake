# frozen_string_literal: true

desc "Fetch reliable and unreliable spec data and create report"
task :reliable_spec_report, [:range, :report_in_issue_and_slack] do |_task, args|
  QA::Tools::ReliableReport.run(**args)
end
