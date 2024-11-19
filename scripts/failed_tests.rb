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
    rspec_pg_regex: /rspec .+ pg14( .+)?/,
    rspec_ee_pg_regex: /rspec-ee .+ pg14( .+)?/
  }.freeze

  def initialize(options)
    @filename = options.delete(:previous_tests_report_path)
    @output_directory = options.delete(:output_directory)
    @format = options.delete(:format).to_sym
    @rspec_pg_regex = options.delete(:rspec_pg_regex)
    @rspec_ee_pg_regex = options.delete(:rspec_ee_pg_regex)
  end

  def output_failed_tests
    create_output_dir

    failed_cases_for_suite_collection.each do |suite_name, suite_tests|
      puts "[FailedTests] Detected #{suite_tests.size} failed tests in suite #{suite_name}..."
      suite_tests =
        case format
        when :oneline
          suite_tests.map { |test| test['file'] }.join(' ') # rubocop:disable Rails/Pluck
        when :json
          JSON.pretty_generate(suite_tests.to_a)
        end

      output_file = File.join(output_directory, "#{suite_name}_failed_tests.#{output_file_format}")

      File.open(output_file, 'w') do |file|
        file.write(suite_tests)
      end
    end
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

  attr_reader :filename, :output_directory, :format, :rspec_pg_regex, :rspec_ee_pg_regex

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
  options = FailedTests::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
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

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  FailedTests.new(options).output_failed_tests
end
