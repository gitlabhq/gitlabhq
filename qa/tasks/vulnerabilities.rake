# frozen_string_literal: true

# How to run this rake task?
# GITLAB_QA_ACCESS_TOKEN=<access_token> GITLAB_URL="<Gitlab address>" bundle exec rake
# vulnerabilities:setup\[<Project_id>,<Vulnerability_count>\] --trace

namespace :vulnerabilities do
  desc "Set up test data for vulnerability report"
  task :setup, [:project_id, :vulnerability_count] do |t, args|
    QA::Runtime::Browser.configure!
    QA::Runtime::Scenario.from_env(QA::Runtime::Env.runtime_scenario_attributes)

    if ENV['GITLAB_URL'].nil?
      puts 'ERROR: Exiting rake, Gitlab address not specified as GITLAB_URL environment variable'
      exit 1
    end

    if ENV['GITLAB_QA_ACCESS_TOKEN'].nil?
      puts 'ERROR: Exiting rake, API access token not provided as GITLAB_QA_ACCESS_TOKEN environment variable'
      exit 1
    end

    QA::Runtime::Scenario.define(:gitlab_address, ENV['GITLAB_URL'])
    vuln = QA::EE::Resource::VulnerabilityReport.new
    vuln.create_vuln_report(args[:project_id], args[:vulnerability_count].to_i)
  end
end
