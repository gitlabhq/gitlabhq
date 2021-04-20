#!/usr/bin/env ruby
# frozen_string_literal: true

####
# Prints a report which helps reconcile occurrences of the `QueryLimiting.disable(ISSUE_LINK)`
# allowlist block against the corresponding open issues.
#
# If everything is consistent, the script should ideally not report any issues or code lines,
# other than possibly remaining "calls with no issue iid" which use variables/etc.
#
# - See https://gitlab.com/gitlab-org/gitlab/-/issues/325640
# - See https://gitlab.com/groups/gitlab-org/-/epics/5670

require 'rubygems'
require 'gitlab'
require 'optparse'

class QueryLimitingReport
  GITLAB_PROJECT_ID = 278964 # gitlab-org/gitlab project
  ISSUES_SEARCH_LABEL = 'querylimiting-disable'
  CODE_LINES_SEARCH_STRING = 'QueryLimiting.disable'
  PAGINATION_LIMIT = 500

  DEFAULT_OPTIONS = {
    api_token: ENV['API_TOKEN']
  }.freeze

  def initialize(options)
    @options = options

    Gitlab.configure do |config|
      config.endpoint = 'https://gitlab.com/api/v4'
      config.private_token = options.fetch(:api_token)
    end
  end

  def execute
    # PLAN:
    # Read all issues matching criteria and extract array of issue iids
    # Find all code references and extract issue iids
    # Print list of all issues without code references
    # Print list of all code references issue iids that don't have search label
    # Print list of all code references with no issue iids (i.e. dynamic or variable argument)

    total_issues = find_issues_by_label(ISSUES_SEARCH_LABEL)
    issues = total_issues.select { |issue| issue[:state] == 'opened' }
    code_lines = find_code_lines

    code_lines_grouped = code_lines.group_by { |code_line| code_line[:has_issue_iid] }
    code_lines_without_issue_iid = code_lines_grouped[false]
    code_lines_with_issue_iid = code_lines_grouped[true]

    all_issue_iids_in_code_lines = code_lines_with_issue_iid.map { |line| line[:issue_iid] }

    issues_without_code_references = issues.reject do |issue|
      all_issue_iids_in_code_lines.include?(issue[:iid])
    end

    all_issue_iids = issues.map { |issue| issue[:iid] }
    code_lines_with_missing_issues = code_lines_with_issue_iid.reject do |code_line|
      all_issue_iids.include?(code_line[:issue_iid])
    end

    puts "\n\n\nREPORT:"

    puts "\n\nFound #{total_issues.length} total issues with '#{ISSUES_SEARCH_LABEL}' search label, #{issues.length} are still opened..."
    puts "\n\nFound #{code_lines.length} total occurrences of '#{CODE_LINES_SEARCH_STRING}' in code..."

    puts "\n" + '-' * 80

    puts "\n\nIssues without any '#{CODE_LINES_SEARCH_STRING}' code references (#{issues_without_code_references.length} total):"
    pp issues_without_code_references

    puts "\n" + '-' * 80

    puts "\n\n'#{CODE_LINES_SEARCH_STRING}' calls with references to an issue which doesn't have '#{ISSUES_SEARCH_LABEL}' search label (#{code_lines_with_missing_issues.length} total):"
    pp code_lines_with_missing_issues

    puts "\n" + '-' * 80

    puts "\n\n'#{CODE_LINES_SEARCH_STRING}' calls with no issue iid (#{code_lines_without_issue_iid&.length || 0} total):"
    pp code_lines_without_issue_iid
  end

  private

  attr_reader :options

  def find_issues_by_label(label)
    issues = []

    puts("Finding issues by label #{label}...")
    paginated_issues = Gitlab.issues(GITLAB_PROJECT_ID, 'labels' => label)
    paginated_issues.paginate_with_limit(PAGINATION_LIMIT) do |item|
      item_hash = item.to_hash

      issue_iid = item_hash.fetch('iid')
      issue = {
        iid: issue_iid,
        state: item_hash.fetch('state'),
        title: item_hash.fetch('title'),
        issue_url: "https://gitlab.com/gitlab-org/gitlab/issues/#{issue_iid}"
      }

      issues << issue
    end

    issues
  end

  def find_code_lines
    code_lines = []

    puts("Finding code lines...")
    paginated_blobs = Gitlab.search_in_project(GITLAB_PROJECT_ID, 'blobs', CODE_LINES_SEARCH_STRING)
    paginated_blobs.paginate_with_limit(PAGINATION_LIMIT) do |item|
      item_hash = item.to_hash

      filename = item_hash.fetch('filename')
      next if filename !~ /\.rb\Z/

      file_contents = Gitlab.file_contents(GITLAB_PROJECT_ID, filename)
      file_lines = file_contents.split("\n")

      file_lines.each_index do |index|
        line = file_lines[index]
        if line =~ /#{CODE_LINES_SEARCH_STRING}/
          issue_iid = line.slice(%r{issues/(\d+)\D}, 1)
          line_number = index + 1
          code_line = {
            file_location: "#{filename}:#{line_number}",
            filename: filename,
            line_number: line_number,
            line: line,
            issue_iid: issue_iid.to_i,
            has_issue_iid: !issue_iid.nil?
          }
          code_lines << code_line
        end
      end
    end

    code_lines.sort_by! { |line| "#{line[:filename]}-#{line[:line_number].to_s.rjust(4, '0')}" }
    code_lines.map do |line|
      line.delete(:filename)
      line.delete(:line_number)
      line
    end
  end
end

if $0 == __FILE__
  options = QueryLimitingReport::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-t", "--api-token API_TOKEN", String, "A value API token with the `read_api` scope. Can be set as an env variable 'API_TOKEN'.") do |value|
      options[:api_token] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  QueryLimitingReport.new(options).execute
end
