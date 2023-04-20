#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'json'
require 'httparty'

require_relative '../api/create_issue'
require_relative '../api/find_issues'
require_relative '../api/update_issue'

class CreateTestFailureIssues
  DEFAULT_OPTIONS = {
    project: nil,
    tests_report_file: 'tests_report.json',
    issue_json_folder: 'tmp/issues/'
  }.freeze

  def initialize(options)
    @options = options
  end

  def execute
    puts "[CreateTestFailureIssues] No failed tests!" if failed_tests.empty?

    failed_tests.each_with_object([]) do |failed_test, existing_issues|
      CreateTestFailureIssue.new(options.dup).upsert(failed_test, existing_issues).tap do |issue|
        existing_issues << issue
        File.write(File.join(options[:issue_json_folder], "issue-#{issue.iid}.json"), JSON.pretty_generate(issue.to_h))
      end
    end
  end

  private

  attr_reader :options

  def failed_tests
    @failed_tests ||=
      if File.exist?(options[:tests_report_file])
        JSON.parse(File.read(options[:tests_report_file]))
      else
        puts "[CreateTestFailureIssues] #{options[:tests_report_file]} doesn't exist!"
        []
      end
  end
end

class CreateTestFailureIssue
  MAX_TITLE_LENGTH = 255
  WWW_GITLAB_COM_SITE = 'https://about.gitlab.com'
  WWW_GITLAB_COM_GROUPS_JSON = "#{WWW_GITLAB_COM_SITE}/groups.json".freeze
  WWW_GITLAB_COM_CATEGORIES_JSON = "#{WWW_GITLAB_COM_SITE}/categories.json".freeze
  FEATURE_CATEGORY_METADATA_REGEX = /(?<=feature_category: :)\w+/
  DEFAULT_LABELS = ['type::maintenance', 'test'].freeze

  def self.server_host
    @server_host ||= ENV.fetch('CI_SERVER_HOST', 'gitlab.com')
  end

  def self.project_path
    @project_path ||= ENV.fetch('CI_PROJECT_PATH', 'gitlab-org/gitlab')
  end

  def self.file_base_url
    @file_base_url ||= "https://#{server_host}/#{project_path}/-/blob/master/"
  end

  def self.report_item_regex
    @report_item_regex ||= %r{^1\. \d{4}-\d{2}-\d{2}: https://#{server_host}/#{project_path}/-/jobs/.+$}
  end

  def initialize(options)
    @project = options.delete(:project)
    @api_token = options.delete(:api_token)
  end

  def upsert(failed_test, existing_issues = [])
    existing_issue = find(failed_test, existing_issues)

    if existing_issue
      update_reports(existing_issue, failed_test)
      existing_issue
    else
      create(failed_test)
    end
  end

  private

  attr_reader :project, :api_token

  def find(failed_test, existing_issues = [])
    test_hash = failed_test_hash(failed_test)
    issue_from_existing_issues = existing_issues.find { |issue| issue.title.include?(test_hash) }
    issue_from_issue_tracker = FindIssues
      .new(project: project, api_token: api_token)
      .execute(state: :opened, search: test_hash, in: :title, per_page: 1)
      .first

    existing_issue = issue_from_existing_issues || issue_from_issue_tracker

    return unless existing_issue

    puts "[CreateTestFailureIssue] Found issue '#{existing_issue.title}': #{existing_issue.web_url}!"

    existing_issue
  end

  def update_reports(existing_issue, failed_test)
    # We count the number of existing reports.
    reports_count = existing_issue.description
      .scan(self.class.report_item_regex)
      .size.to_i + 1

    # We include the number of reports in the header, for visibility.
    issue_description = existing_issue.description.sub(/^### Reports.*$/, "### Reports (#{reports_count})")

    # We add the current failure to the list of reports.
    issue_description = "#{issue_description}\n#{report_list_item(failed_test)}"

    UpdateIssue
      .new(project: project, api_token: api_token)
      .execute(
        existing_issue.iid,
        description: issue_description,
        weight: reports_count
      )
    puts "[CreateTestFailureIssue] Added a report in '#{existing_issue.title}': #{existing_issue.web_url}!"
  end

  def create(failed_test)
    payload = {
      title: failed_test_issue_title(failed_test),
      description: failed_test_issue_description(failed_test),
      labels: failed_test_issue_labels(failed_test),
      weight: 1
    }

    CreateIssue.new(project: project, api_token: api_token).execute(payload).tap do |issue|
      puts "[CreateTestFailureIssue] Created issue '#{issue.title}': #{issue.web_url}!"
    end
  end

  def failed_test_hash(failed_test)
    Digest::SHA256.hexdigest(failed_test['file'] + failed_test['name'])[0...12]
  end

  def failed_test_issue_title(failed_test)
    title = "#{failed_test['file']} [test-hash:#{failed_test_hash(failed_test)}]"

    raise "Title is too long!" if title.size > MAX_TITLE_LENGTH

    title
  end

  def test_file_link(failed_test)
    "[`#{failed_test['file']}`](#{self.class.file_base_url}#{failed_test['file']})"
  end

  def report_list_item(failed_test)
    "1. #{Time.new.utc.strftime('%F')}: #{failed_test['job_url']} (#{ENV['CI_PIPELINE_URL']})"
  end

  def failed_test_issue_description(failed_test)
    <<~DESCRIPTION
    ### Test description

    `#{search_safe(failed_test['name'])}`

    ### Test file path

    #{test_file_link(failed_test)}

    <!-- Don't add anything after the report list since it's updated automatically -->
    ### Reports (1)

    #{report_list_item(failed_test)}
    DESCRIPTION
  end

  def failed_test_issue_labels(failed_test)
    labels = DEFAULT_LABELS + category_and_group_labels_for_test_file(failed_test['file'])

    # make sure we don't spam people who are notified to actual labels
    labels.map { |label| "wip-#{label}" }
  end

  def category_and_group_labels_for_test_file(test_file)
    feature_categories = File.open(File.expand_path(File.join('..', '..', test_file), __dir__))
      .read
      .scan(FEATURE_CATEGORY_METADATA_REGEX)

    category_labels = feature_categories.filter_map { |category| categories_mapping.dig(category, 'label') }.uniq

    groups = feature_categories.filter_map { |category| categories_mapping.dig(category, 'group') }
    group_labels = groups.map { |group| groups_mapping.dig(group, 'label') }.uniq

    (category_labels + [group_labels.first]).compact
  end

  def categories_mapping
    @categories_mapping ||= self.class.fetch_json(WWW_GITLAB_COM_CATEGORIES_JSON)
  end

  def groups_mapping
    @groups_mapping ||= self.class.fetch_json(WWW_GITLAB_COM_GROUPS_JSON)
  end

  def search_safe(value)
    value.delete('"')
  end

  def self.fetch_json(json_url)
    json = with_retries { HTTParty.get(json_url, format: :plain) } # rubocop:disable Gitlab/HTTParty
    JSON.parse(json)
  end

  def self.with_retries(attempts: 3)
    yield
  rescue Errno::ECONNRESET, OpenSSL::SSL::SSLError, Net::OpenTimeout
    retry if (attempts -= 1) > 0
    raise
  end
  private_class_method :with_retries
end

if $PROGRAM_NAME == __FILE__
  options = CreateTestFailureIssues::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-p", "--project PROJECT", String,
      "Project where to create the issue (defaults to " \
      "`#{CreateTestFailureIssues::DEFAULT_OPTIONS[:project]}`)") do |value|
      options[:project] = value
    end

    opts.on("-r", "--tests-report-file file_path", String,
      "Path to a JSON file which contains the current pipeline's tests report (defaults to " \
      "`#{CreateTestFailureIssues::DEFAULT_OPTIONS[:tests_report_file]}`)"
    ) do |value|
      options[:tests_report_file] = value
    end

    opts.on("-f", "--issues-json-folder file_path", String,
      "Path to a folder where to save the issues JSON data (defaults to " \
      "`#{CreateTestFailureIssues::DEFAULT_OPTIONS[:issue_json_folder]}`)") do |value|
      options[:issue_json_folder] = value
    end

    opts.on("-t", "--api-token API_TOKEN", String,
      "A valid Project token with the `Reporter` role and `api` scope to create the issue") do |value|
      options[:api_token] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  CreateTestFailureIssues.new(options).execute
end
