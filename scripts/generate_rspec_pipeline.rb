#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'json'
require 'fileutils'
require 'erb'
require_relative '../tooling/quality/test_level'

# Class to generate RSpec test child pipeline with dynamically parallelized jobs.
class GenerateRspecPipeline
  SKIP_PIPELINE_YML_FILE = ".gitlab/ci/_skip.yml"
  TEST_LEVELS = %i[migration background_migration unit integration system].freeze
  MAX_NODES_COUNT = 50 # Maximum parallelization allowed by GitLab

  OPTIMAL_TEST_JOB_DURATION_IN_SECONDS = 600 # 10 MINUTES
  SETUP_DURATION_IN_SECONDS = 180.0 # 3 MINUTES
  OPTIMAL_TEST_RUNTIME_DURATION_IN_SECONDS = OPTIMAL_TEST_JOB_DURATION_IN_SECONDS - SETUP_DURATION_IN_SECONDS

  # As of 2024-07-16:
  # $ find spec -type f | wc -l
  #  16007 (`SPEC_FILES_COUNT`)
  # and
  # $ find ee/spec -type f | wc -l
  #  8548 (`EE_SPEC_FILES_COUNT`)
  # which gives a total of 24555 test files (`ALL_SPEC_FILES_COUNT`).
  #
  # Total time to run all tests (based on https://gitlab-org.gitlab.io/rspec_profiling_stats/)
  # is 251509 seconds (`TEST_SUITE_DURATION_IN_SECONDS`).
  #
  # This gives an approximate 251509 / 24555 = 10.2 seconds per test file
  # (`DEFAULT_AVERAGE_TEST_FILE_DURATION_IN_SECONDS`).
  #
  # If we want each test job to finish in 10 minutes, given we have 3 minutes of setup (`SETUP_DURATION_IN_SECONDS`),
  # then we need to give 7 minutes of testing to each test node (`OPTIMAL_TEST_RUNTIME_DURATION_IN_SECONDS`).
  # (7 * 60) / 10.2 = 41.17
  #
  # So if we'd want to run the full test suites in 10 minutes (`OPTIMAL_TEST_JOB_DURATION_IN_SECONDS`),
  # we'd need to run at max 41 test file per nodes (`#optimal_test_file_count_per_node_per_test_level`).
  SPEC_FILES_COUNT = 16007
  EE_SPEC_FILES_COUNT = 8548
  ALL_SPEC_FILES_COUNT = SPEC_FILES_COUNT + EE_SPEC_FILES_COUNT
  TEST_SUITE_DURATION_IN_SECONDS = 251509
  DEFAULT_AVERAGE_TEST_FILE_DURATION_IN_SECONDS = TEST_SUITE_DURATION_IN_SECONDS / ALL_SPEC_FILES_COUNT

  # pipeline_template_path: A YAML pipeline configuration template to generate the final pipeline config from
  # rspec_files_path: A file containing RSpec files to run, separated by a space
  # knapsack_report_path: A file containing a Knapsack report
  # test_suite_prefix: An optional test suite folder prefix (e.g. `ee/` or `jh/`)
  # generated_pipeline_path: An optional filename where to write the pipeline config (defaults to
  #                          `"#{pipeline_template_path}.yml"`)
  def initialize(
    pipeline_template_path:, rspec_files_path: nil, knapsack_report_path: nil, test_suite_prefix: nil,
    job_tags: [], generated_pipeline_path: nil)
    @pipeline_template_path = pipeline_template_path.to_s
    @rspec_files_path = rspec_files_path.to_s
    @knapsack_report_path = knapsack_report_path.to_s
    @test_suite_prefix = test_suite_prefix
    @job_tags = job_tags
    @generated_pipeline_path = generated_pipeline_path || "#{pipeline_template_path}.yml"

    raise ArgumentError unless File.exist?(@pipeline_template_path)
  end

  def generate!
    if all_rspec_files.empty?
      info "Using #{SKIP_PIPELINE_YML_FILE} due to no RSpec files to run"
      FileUtils.cp(SKIP_PIPELINE_YML_FILE, generated_pipeline_path)
      return
    end

    info "pipeline_template_path: #{pipeline_template_path}"
    info "generated_pipeline_path: #{generated_pipeline_path}"

    File.open(generated_pipeline_path, 'w') do |handle|
      pipeline_yaml = ERB.new(File.read(pipeline_template_path), trim_mode: '-').result_with_hash(**erb_binding)
      handle.write(pipeline_yaml.squeeze("\n").strip)
    end
  end

  private

  attr_reader :pipeline_template_path, :rspec_files_path, :knapsack_report_path, :test_suite_prefix,
    :job_tags, :generated_pipeline_path

  def info(text)
    $stdout.puts "[#{self.class.name}] #{text}"
  end

  def all_rspec_files
    @all_rspec_files ||= File.exist?(rspec_files_path) ? File.read(rspec_files_path).split(' ') : []
  end

  def erb_binding
    {
      rspec_files_per_test_level: rspec_files_per_test_level,
      test_suite_prefix: test_suite_prefix,
      repo_from_artifacts: ENV['CI_FETCH_REPO_GIT_STRATEGY'] == 'none',
      job_tags: job_tags
    }
  end

  def rspec_files_per_test_level
    @rspec_files_per_test_level ||= begin
      all_remaining_rspec_files = all_rspec_files.dup
      TEST_LEVELS.each_with_object(Hash.new { |h, k| h[k] = {} }) do |test_level, memo|
        memo[test_level][:files] = all_remaining_rspec_files
          .grep(test_level_service.regexp(test_level, true))
          .tap { |files| files.each { |file| all_remaining_rspec_files.delete(file) } }
        memo[test_level][:parallelization] = optimal_nodes_count(test_level, memo[test_level][:files])
      end
    end
  end

  def optimal_nodes_count(test_level, rspec_files)
    nodes_count = (rspec_files.size / optimal_test_file_count_per_node_per_test_level(test_level, rspec_files)).ceil
    info "Optimal node count for #{rspec_files.size} #{test_level} RSpec files is #{nodes_count}."

    if nodes_count > MAX_NODES_COUNT
      info "We don't want to parallelize to more than #{MAX_NODES_COUNT} jobs for now! " \
           "Decreasing the parallelization to #{MAX_NODES_COUNT}."

      MAX_NODES_COUNT
    else
      nodes_count
    end
  end

  def optimal_test_file_count_per_node_per_test_level(test_level, rspec_files)
    [
      (OPTIMAL_TEST_RUNTIME_DURATION_IN_SECONDS / average_test_file_duration(test_level, rspec_files)),
      1
    ].max
  end

  def average_test_file_duration(test_level, rspec_files)
    if rspec_files.any? && knapsack_report.any?
      rspec_files_duration = rspec_files.sum do |rspec_file|
        knapsack_report.fetch(
          rspec_file, average_test_file_duration_per_test_level[test_level])
      end

      rspec_files_duration / rspec_files.size
    else
      average_test_file_duration_per_test_level[test_level]
    end
  end

  def average_test_file_duration_per_test_level
    @optimal_test_file_count_per_node_per_test_level ||=
      if knapsack_report.any?
        remaining_knapsack_report = knapsack_report.dup
        TEST_LEVELS.each_with_object({}) do |test_level, memo|
          matching_data_per_test_level = remaining_knapsack_report
            .select { |test_file, _| test_file.match?(test_level_service.regexp(test_level, true)) }
            .tap { |test_data| test_data.each { |file, _| remaining_knapsack_report.delete(file) } }

          memo[test_level] =
            if matching_data_per_test_level.empty?
              DEFAULT_AVERAGE_TEST_FILE_DURATION_IN_SECONDS
            else
              matching_data_per_test_level.values.sum / matching_data_per_test_level.keys.size
            end
        end
      else
        TEST_LEVELS.each_with_object({}) do |test_level, memo| # rubocop:disable Rails/IndexWith
          memo[test_level] = DEFAULT_AVERAGE_TEST_FILE_DURATION_IN_SECONDS
        end
      end
  end

  def knapsack_report
    @knapsack_report ||=
      begin
        File.exist?(knapsack_report_path) ? JSON.parse(File.read(knapsack_report_path)) : {}
      rescue JSON::ParserError => e
        info "[ERROR] Knapsack report at #{knapsack_report_path} couldn't be parsed! Error:\n#{e}"
        {}
      end
  end

  def test_level_service
    @test_level_service ||= Quality::TestLevel.new(test_suite_prefix)
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}

  OptionParser.new do |opts|
    opts.on("-f", "--rspec-files-path path", String, "Path to a file containing RSpec files to run, " \
                                                     "separated by a space") do |value|
      options[:rspec_files_path] = value
    end

    opts.on("-t", "--pipeline-template-path PATH", String, "Path to a YAML pipeline configuration template to " \
                                                           "generate the final pipeline config from") do |value|
      options[:pipeline_template_path] = value
    end

    opts.on("-k", "--knapsack-report-path path", String, "Path to a Knapsack report") do |value|
      options[:knapsack_report_path] = value
    end

    opts.on("-p", "--test-suite-prefix test_suite_prefix", String, "Test suite folder prefix") do |value|
      options[:test_suite_prefix] = value
    end

    opts.on("-j", "--job-tags job_tags", String, "Job tags (default to `[]`) " \
                                                 "separated by commas") do |value|
      options[:job_tags] = value.split(',')
    end

    opts.on("-o", "--generated-pipeline-path generated_pipeline_path", String, "Path where to write the pipeline " \
                                                                               "config") do |value|
      options[:generated_pipeline_path] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  GenerateRspecPipeline.new(**options).generate!
end
