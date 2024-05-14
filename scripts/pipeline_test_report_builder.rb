#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'time'
require 'fileutils'
require 'uri'
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
  DEFAULT_OPTIONS = {
    target_project: Host::DEFAULT_OPTIONS[:target_project] || API::DEFAULT_OPTIONS[:project],
    current_pipeline_id: API::DEFAULT_OPTIONS[:pipeline_id],
    mr_iid: Host::DEFAULT_OPTIONS[:mr_iid],
    api_endpoint: API::DEFAULT_OPTIONS[:endpoint],
    output_file_path: 'test_results/test_reports.json',
    pipeline_index: :previous
  }.freeze

  def initialize(options)
    @target_project = options.delete(:target_project)
    @current_pipeline_id = options.delete(:current_pipeline_id)
    @mr_iid = options.delete(:mr_iid)
    @api_endpoint = options.delete(:api_endpoint).to_s
    @output_file_path = options.delete(:output_file_path).to_s
    @pipeline_index = options.delete(:pipeline_index).to_sym
  end

  def execute
    FileUtils.mkdir_p(File.dirname(output_file_path))

    File.open(output_file_path, 'w') do |file|
      file.write(test_report_for_pipeline)
    end
  end

  def test_report_for_pipeline
    build_test_report_json_for_pipeline
  end

  def latest_pipeline
    fetch("#{target_project_api_base_url}/pipelines/#{current_pipeline_id}")
  end

  def previous_pipeline
    # Top of the list will always be the latest pipeline
    # Second from top will be the previous pipeline
    pipelines_sorted_descending[1]
  end

  private

  attr_reader :target_project, :current_pipeline_id, :mr_iid, :api_endpoint, :output_file_path, :pipeline_index

  def pipeline
    @pipeline ||=
      case pipeline_index
      when :latest
        latest_pipeline
      when :previous
        previous_pipeline
      else
        raise "[PipelineTestReportBuilder] Unsupported pipeline_index `#{pipeline_index}` (allowed index: `latest` and `previous`!"
      end
  end

  def pipelines_sorted_descending
    # Top of the list will always be the current pipeline
    # Second from top will be the previous pipeline
    pipelines_for_mr.sort_by { |a| -a['id'] }
  end

  def pipeline_project_api_base_url(pipeline)
    "#{api_endpoint}/projects/#{pipeline['project_id']}"
  end

  def target_project_api_base_url
    "#{api_endpoint}/projects/#{target_project}"
  end

  def pipelines_for_mr
    @pipelines_for_mr ||= fetch("#{target_project_api_base_url}/merge_requests/#{mr_iid}/pipelines")
  end

  def failed_builds_for_pipeline
    fetch("#{pipeline_project_api_base_url(pipeline)}/pipelines/#{pipeline['id']}/jobs?scope=failed&per_page=100")
  end

  # Method uses the test suite endpoint to gather test results for a particular build.
  # Here we request individual builds, even though it is possible to supply multiple build IDs.
  # The reason for this; it is possible to lose the job context and name when requesting multiple builds.
  # Please see for more info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69053#note_709939709
  def test_report_for_build(pipeline_url, build_id)
    fetch("#{pipeline_url}/tests/suite.json?build_ids[]=#{build_id}").tap do |suite|
      suite['job_url'] = job_url(pipeline_url, build_id)
    end
  rescue Net::HTTPClientException => e
    raise e unless e.response.code.to_i == 404

    puts "[PipelineTestReportBuilder] Artifacts not found. They may have expired. Skipping this build."
  end

  def build_test_report_json_for_pipeline
    # empty file if no previous failed pipeline
    return {}.to_json if pipeline.nil?

    test_report = { 'suites' => [] }

    puts "[PipelineTestReportBuilder] Discovered #{pipeline_index} failed pipeline (##{pipeline['id']}) for MR!#{mr_iid}"

    failed_builds_for_pipeline.each do |failed_build|
      next if failed_build['stage'] != 'test'

      test_report['suites'] << test_report_for_build(pipeline['web_url'], failed_build['id'])
    end

    test_report['suites'].compact!

    puts "[PipelineTestReportBuilder] #{test_report['suites'].size} failed builds in test stage found..."

    test_report.to_json
  end

  def job_url(pipeline_url, build_id)
    pipeline_url.sub(%r{/pipelines/.+}, "/jobs/#{build_id}")
  end

  def fetch(uri_str)
    uri = URI(uri_str)

    puts "[PipelineTestReportBuilder] URL: #{uri}"

    request = Net::HTTP::Get.new(uri)

    body = ''

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(request) do |response|
        case response
        when Net::HTTPSuccess
          body = response.read_body
        else
          raise "[PipelineTestReportBuilder] Unexpected response: #{response.value}"
        end
      end
    end

    JSON.parse(body)
  end
end

if $PROGRAM_NAME == __FILE__
  options = PipelineTestReportBuilder::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-o", "--output-file-path OUTPUT_PATH", String, "A path for output file") do |value|
      options[:output_file_path] = value
    end

    opts.on("-p", "--pipeline-index [latest|previous]", String, "What pipeline to retrieve (defaults to `#{PipelineTestReportBuilder::DEFAULT_OPTIONS[:pipeline_index]}`)") do |value|
      options[:pipeline_index] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  PipelineTestReportBuilder.new(options).execute
end
