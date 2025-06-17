#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'uri'
require 'json'

class FailedTests
  DEFAULT_OPTIONS = {
    previous_tests_report_path: 'test_results/previous/test_reports.json',
    output_directory: 'tmp/previous_failed_tests/',
    format: :oneline,
    rspec_pg_regex: /rspec .+ pg16( .+)?/,
    rspec_ee_pg_regex: /rspec-ee .+ pg16( .+)?/,
    rspec_regex: /rspec/,
    single_output: false
  }.freeze

  def self.parse_cli_options(args = ARGV)
    options = FailedTests::DEFAULT_OPTIONS.dup

    parser = OptionParser.new do |opts|
      opts.on("-p", "--previous-tests-report-path PREVIOUS_TESTS_REPORT_PATH", String,
        "Path of the file listing previous test failures (defaults to " \
        "`#{FailedTests::DEFAULT_OPTIONS[:previous_tests_report_path]}`)") do |value|
        options[:previous_tests_report_path] = value
      end

      opts.on("-o", "--output-directory OUTPUT_DIRECTORY", String,
        "Output directory for failed test files (defaults to " \
        "`#{FailedTests::DEFAULT_OPTIONS[:output_directory]}`)") do |value|
        options[:output_directory] = value
      end

      opts.on("-f", "--format [oneline|json]", String,
        "Format of the output files: oneline (with test filenames) or JSON (defaults to " \
        "`#{FailedTests::DEFAULT_OPTIONS[:format]}`)") do |value|
        options[:format] = value
      end

      opts.on("--rspec-pg-regex RSPEC_PG_REGEX", Regexp,
        "Regex to use when finding matching RSpec jobs (defaults to " \
        "`#{FailedTests::DEFAULT_OPTIONS[:rspec_pg_regex]}`)") do |value|
        options[:rspec_pg_regex] = value
      end

      opts.on("--rspec-ee-pg-regex RSPEC_EE_PG_REGEX", Regexp,
        "Regex to use when finding matching RSpec EE jobs (defaults to " \
        "`#{FailedTests::DEFAULT_OPTIONS[:rspec_ee_pg_regex]}`)") do |value|
        options[:rspec_ee_pg_regex] = value
      end

      opts.on("--single-output", "Output all rspec failed tests to a single file instead of categorizing by suite") do
        options[:single_output] = true
      end

      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    parser.parse!(args)
    options
  end

  def initialize(options)
    @filename = options.delete(:previous_tests_report_path)
    @output_directory = options.delete(:output_directory)
    @format = options.delete(:format).to_sym
    @rspec_pg_regex = options.delete(:rspec_pg_regex)
    @rspec_ee_pg_regex = options.delete(:rspec_ee_pg_regex)
    @single_output = options.delete(:single_output)
  end

  def output_all_failed_rspec_tests
    create_output_dir

    all_failed_tests = []

    rspec_failed_suites = failed_suites.select do |suite|
      suite['name'].match?(FailedTests::DEFAULT_OPTIONS[:rspec_regex])
    end

    rspec_failed_suites.each do |suite|
      failed_cases(suite).each do |test_case|
        all_failed_tests << test_case
      end
    end

    puts "[FailedTests] Detected #{all_failed_tests.size} total RSpec failed tests across all suites..."

    write_failed_tests_to_file("rspec_all_failed_tests", all_failed_tests)
    puts "[FailedTests] All RSpec failed tests written to #{File.join(output_directory,
      "rspec_all_failed_tests.#{output_file_format}")}"
  end

  def output_failed_tests
    return output_all_failed_rspec_tests if single_output

    create_output_dir

    failed_cases_for_suite_collection.each do |suite_name, suite_tests|
      puts "[FailedTests] Detected #{suite_tests.size} failed tests in suite #{suite_name}..."

      write_failed_tests_to_file("#{suite_name}_failed_tests", suite_tests)
    end
  end

  def write_failed_tests_to_file(filename_prefix, failed_tests)
    formatted_tests =
      case format
      when :oneline
        # Deduplicate file paths for oneline format since we only output filenames
        unique_files = failed_tests.map { |test| test['file'] }.uniq # rubocop:disable Rails/Pluck
        unique_files.join(' ')
      when :json
        # Preserve all test case objects for JSON format to maintain full context
        JSON.pretty_generate(failed_tests.to_a)
      end

    output_file = File.join(output_directory, "#{filename_prefix}.#{output_file_format}")

    File.write(output_file, formatted_tests)
  end

  def failed_cases_for_suite_collection
    suite_map.each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |(suite_name, suite_collection_regex), hash|
      failed_suites.each do |suite|
        hash[suite_name].merge(failed_cases(suite)) if suite_collection_regex.match?(suite['name'])
      end
    end
  end

  def suite_map
    @suite_map ||= {
      rspec: rspec_pg_regex,
      rspec_ee: rspec_ee_pg_regex,
      jest: /jest/
    }
  end

  private

  attr_reader :filename, :output_directory, :format, :rspec_pg_regex, :rspec_ee_pg_regex, :single_output

  def file_contents
    @file_contents ||= begin
      File.read(filename)
    rescue Errno::ENOENT
      '{}'
    end
  end

  def file_contents_as_json
    @file_contents_as_json ||= begin
      JSON.parse(file_contents)
    rescue JSON::ParserError
      {}
    end
  end

  def output_file_format
    case format
    when :oneline
      'txt'
    when :json
      'json'
    else
      raise "[FailedTests] Unsupported format `#{format}` (allowed formats: `oneline` and `json`)!"
    end
  end

  def failed_suites
    return [] unless file_contents_as_json['suites']

    file_contents_as_json['suites'].select { |suite| suite['failed_count'] > 0 }
  end

  def failed_cases(suite)
    return [] unless suite

    suite['test_cases'].filter_map do |failure_hash|
      next if failure_hash['status'] != 'failed'

      failure_hash['job_url'] = suite['job_url']
      failure_hash['file'] = failure_hash['file'].delete_prefix('./')

      failure_hash
    end
  end

  def create_output_dir
    return if File.directory?(output_directory)

    puts '[FailedTests] Creating output directory...'
    FileUtils.mkdir_p(output_directory)
  end
end

if $PROGRAM_NAME == __FILE__
  options = FailedTests.parse_cli_options
  FailedTests.new(options).output_failed_tests
end
