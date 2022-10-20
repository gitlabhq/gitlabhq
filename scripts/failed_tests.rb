#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'uri'
require 'json'
require 'set'

class FailedTests
  def initialize(options)
    @filename = options.delete(:previous_tests_report_path)
    @output_directory = options.delete(:output_directory)
    @rspec_pg_regex = options.delete(:rspec_pg_regex)
    @rspec_ee_pg_regex = options.delete(:rspec_ee_pg_regex)
  end

  def output_failed_test_files
    create_output_dir

    failed_files_for_suite_collection.each do |suite_collection_name, suite_collection_files|
      failed_test_files = suite_collection_files.map { |filepath| filepath.delete_prefix('./') }.join(' ')

      output_file = File.join(output_directory, "#{suite_collection_name}_failed_files.txt")

      File.open(output_file, 'w') do |file|
        file.write(failed_test_files)
      end
    end
  end

  def failed_files_for_suite_collection
    suite_map.each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |(suite_collection_name, suite_collection_regex), hash|
      failed_suites.each do |suite|
        hash[suite_collection_name].merge(failed_files(suite)) if suite['name'] =~ suite_collection_regex
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

  attr_reader :filename, :output_directory, :rspec_pg_regex, :rspec_ee_pg_regex

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

  def failed_suites
    return [] unless file_contents_as_json['suites']

    file_contents_as_json['suites'].select { |suite| suite['failed_count'] > 0 }
  end

  def failed_files(suite)
    return [] unless suite

    suite['test_cases'].each_with_object([]) do |failure_hash, failed_cases|
      failed_cases << failure_hash['file'] if failure_hash['status'] == 'failed'
    end
  end

  def create_output_dir
    return if File.directory?(output_directory)

    puts 'Creating output directory...'
    FileUtils.mkdir_p(output_directory)
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    previous_tests_report_path: 'test_results/previous/test_reports.json',
    output_directory: 'tmp/previous_failed_tests/',
    rspec_pg_regex: /rspec .+ pg12( .+)?/,
    rspec_ee_pg_regex: /rspec-ee .+ pg12( .+)?/
  }

  OptionParser.new do |opts|
    opts.on("-p", "--previous-tests-report-path PREVIOUS_TESTS_REPORT_PATH", String, "Path of the file listing previous test failures") do |value|
      options[:previous_tests_report_path] = value
    end

    opts.on("-o", "--output-directory OUTPUT_DIRECTORY", String, "Output directory for failed test files") do |value|
      options[:output_directory] = value
    end

    opts.on("--rspec-pg-regex RSPEC_PG_REGEX", Regexp, "Regex to use when finding matching RSpec jobs") do |value|
      options[:rspec_pg_regex] = value
    end

    opts.on("--rspec-ee-pg-regex RSPEC_EE_PG_REGEX", Regexp, "Regex to use when finding matching RSpec EE jobs") do |value|
      options[:rspec_ee_pg_regex] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  FailedTests.new(options).output_failed_test_files
end
