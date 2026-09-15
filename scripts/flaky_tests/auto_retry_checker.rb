#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

# Checks whether any of the failed spec files from an RSpec run are known flaky tests.
# If so, exits with code 112 to trigger a GitLab CI job-level auto-retry.
# Exits 0 when no known flaky test is found.
# Fails open: network or parse errors are logged and treated as "not flaky".
class AutoRetryChecker
  EXIT_CODE_KNOWN_FLAKY = 112

  def initialize(last_run_results_path:, flaky_test_list_url: ENV['GLCI_FLAKY_TEST_LIST_URL'])
    @last_run_results_path = last_run_results_path
    @flaky_test_list_url = flaky_test_list_url
  end

  def run
    return unless @flaky_test_list_url

    failed_files = extract_failed_files
    return if failed_files.empty?

    flaky_files = fetch_flaky_files
    return if flaky_files.empty?

    match = failed_files.find { |f| flaky_files.include?(f) }
    return unless match

    warn "Known flaky test detected in '#{match}'. Exiting with code #{EXIT_CODE_KNOWN_FLAKY} to trigger CI auto-retry."
    exit EXIT_CODE_KNOWN_FLAKY
  end

  private

  def extract_failed_files
    return [] unless File.exist?(@last_run_results_path)

    File.readlines(@last_run_results_path, chomp: true)
      .select { |line| line.include?(' failed') }
      .filter_map { |line| line[%r{\./(\S+_spec\.rb)}, 1] }
      .uniq
  end

  def fetch_flaky_files
    response = fetch_url(@flaky_test_list_url)
    return [] unless response

    in_mr = ENV['CI_MERGE_REQUEST_IID']
    JSON.parse(response).filter_map do |entry|
      next if in_mr && entry['master_only_flaky']

      entry['file_path']
    end
  rescue JSON::ParserError, TypeError => e
    warn "Failed to parse flaky test list: #{e.message}"
    []
  end

  def fetch_url(url, redirect_limit: 2)
    return if redirect_limit == 0

    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 10) do |http|
      http.get(uri.request_uri)
    end

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      fetch_url(response['location'], redirect_limit: redirect_limit - 1)
    else
      warn "Failed to fetch flaky test list (HTTP #{response.code}): #{url}"
      nil
    end
  rescue StandardError => e
    warn "Failed to fetch flaky test list: #{e.message}"
    nil
  end
end

if $PROGRAM_NAME == __FILE__
  last_run_results_path = ENV.fetch('RSPEC_LAST_RUN_RESULTS_FILE', 'tmp/rspec_last_run_results.txt')
  AutoRetryChecker.new(last_run_results_path: last_run_results_path).run
end
