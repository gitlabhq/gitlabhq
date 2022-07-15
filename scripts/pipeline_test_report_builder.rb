#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'time'
require 'fileutils'
require 'uri'
require 'cgi'
require 'net/http'
require 'json'
require_relative 'api/default_options'

# Request list of pipelines for MR
# https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/merge_requests/69053/pipelines
# Find latest failed pipeline
# Retrieve list of failed builds for test stage in pipeline
# https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/pipelines/363788864/jobs/?scope=failed
# Retrieve test reports for these builds
# https://gitlab.com/gitlab-org/gitlab/-/pipelines/363788864/tests/suite.json?build_ids[]=1555608749
# Push into expected format for failed tests
class PipelineTestReportBuilder
  def initialize(options)
    @target_project = options.delete(:target_project)
    @mr_id = options.delete(:mr_id) || Host::DEFAULT_OPTIONS[:mr_id]
    @instance_base_url = options.delete(:instance_base_url) || Host::DEFAULT_OPTIONS[:instance_base_url]
    @output_file_path = options.delete(:output_file_path)
  end

  def test_report_for_latest_pipeline
    build_test_report_json_for_pipeline(previous_pipeline)
  end

  def execute
    if output_file_path
      FileUtils.mkdir_p(File.dirname(output_file_path))
    end

    File.open(output_file_path, 'w') do |file|
      file.write(test_report_for_latest_pipeline)
    end
  end

  def previous_pipeline
    # Top of the list will always be the current pipeline
    # Second from top will be the previous pipeline
    pipelines_for_mr.sort_by { |a| -Time.parse(a['created_at']).to_i }[1]
  end

  private

  attr_reader :target_project, :mr_id, :instance_base_url, :output_file_path

  def pipeline_project_api_base_url(pipeline)
    "#{instance_base_url}/api/v4/projects/#{pipeline['project_id']}"
  end

  def target_project_api_base_url
    "#{instance_base_url}/api/v4/projects/#{CGI.escape(target_project)}"
  end

  def pipelines_for_mr
    fetch("#{target_project_api_base_url}/merge_requests/#{mr_id}/pipelines")
  end

  def failed_builds_for_pipeline(pipeline)
    fetch("#{pipeline_project_api_base_url(pipeline)}/pipelines/#{pipeline['id']}/jobs?scope=failed&per_page=100")
  end

  # Method uses the test suite endpoint to gather test results for a particular build.
  # Here we request individual builds, even though it is possible to supply multiple build IDs.
  # The reason for this; it is possible to lose the job context and name when requesting multiple builds.
  # Please see for more info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69053#note_709939709
  def test_report_for_build(pipeline, build_id)
    fetch("#{pipeline['web_url']}/tests/suite.json?build_ids[]=#{build_id}")
  rescue Net::HTTPServerException => e
    raise e unless e.response.code.to_i == 404

    puts "Artifacts not found. They may have expired. Skipping this build."
  end

  def build_test_report_json_for_pipeline(pipeline)
    # empty file if no previous failed pipeline
    return {}.to_json if pipeline.nil? || pipeline['status'] != 'failed'

    test_report = {}

    puts "Discovered last failed pipeline (#{pipeline['id']}) for MR!#{mr_id}"

    failed_builds_for_test_stage = failed_builds_for_pipeline(pipeline).select do |failed_build|
      failed_build['stage'] == 'test'
    end

    puts "#{failed_builds_for_test_stage.length} failed builds in test stage found..."

    if failed_builds_for_test_stage.any?
      test_report['suites'] ||= []

      failed_builds_for_test_stage.each do |failed_build|
        suite = test_report_for_build(pipeline, failed_build['id'])
        test_report['suites'] << suite if suite
      end
    end

    test_report.to_json
  end

  def fetch(uri_str)
    uri = URI(uri_str)

    puts "URL: #{uri}"

    request = Net::HTTP::Get.new(uri)

    body = ''

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        case response
        when Net::HTTPSuccess
          body = response.read_body
        else
          raise "Unexpected response: #{response.value}"
        end
      end
    end

    JSON.parse(body)
  end
end

if $0 == __FILE__
  options = Host::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-t", "--target-project TARGET_PROJECT", String, "Project where to find the merge request") do |value|
      options[:target_project] = value
    end

    opts.on("-m", "--mr-id MR_ID", String, "A merge request ID") do |value|
      options[:mr_id] = value
    end

    opts.on("-i", "--instance-base-url INSTANCE_BASE_URL", String, "URL of the instance where project and merge request resides") do |value|
      options[:instance_base_url] = value
    end

    opts.on("-o", "--output-file-path OUTPUT_PATH", String, "A path for output file") do |value|
      options[:output_file_path] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  PipelineTestReportBuilder.new(options).execute
end
