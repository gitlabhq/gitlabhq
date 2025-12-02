#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'tempfile'

# Base class for downloading artifacts from child pipelines
# triggered by bridge jobs like e2e:test-on-gdk.
#
# This workaround is needed because GitLab CI doesn't yet provide a direct way
# to access artifacts from child pipelines. See:
# - https://gitlab.com/gitlab-org/gitlab/-/issues/285100 (Allow job in upstream pipeline to reference artifacts)
# - https://gitlab.com/groups/gitlab-org/-/epics/8205 (Read child pipeline artifacts for MR reports)
#
# Note: We use Net::HTTP instead of the gitlab gem because the gem's job_artifacts
# method doesn't properly handle redirects to Google Cloud Storage (GCS), resulting
# in malformed URLs like "https://storage.googleapis.com:443https://storage.googleapis.com/..."
class ChildPipelineArtifactDownloader
  def initialize(bridge_name:, job_name:, coverage_type:)
    @bridge_name = bridge_name
    @job_name = job_name
    @coverage_type = coverage_type
    @api_url = ENV.fetch('CI_API_V4_URL')
    @project_id = ENV.fetch('CI_PROJECT_ID')
    @pipeline_id = ENV.fetch('CI_PIPELINE_ID')
    @job_token = ENV.fetch('CI_JOB_TOKEN')
  end

  def run
    child_pipeline_id = find_child_pipeline_id
    return false unless child_pipeline_id

    job_id = find_job_id(child_pipeline_id)
    return false unless job_id

    download_artifacts(job_id)
    true
  end

  private

  def find_child_pipeline_id
    puts "Finding child pipeline ID from #{@bridge_name} trigger job..."

    response = api_request("projects/#{@project_id}/pipelines/#{@pipeline_id}/bridges")
    bridges = JSON.parse(response.body)

    bridge = bridges.find { |b| b['name'] == @bridge_name }

    if bridge.nil? || bridge.dig('downstream_pipeline', 'id').nil?
      puts "Could not find child pipeline ID. Skipping E2E #{@coverage_type} coverage export."
      return
    end

    child_pipeline_id = bridge.dig('downstream_pipeline', 'id')
    puts "Child pipeline ID: #{child_pipeline_id}"
    child_pipeline_id
  end

  def find_job_id(pipeline_id)
    puts "Finding #{@job_name} job in child pipeline..."

    response = api_request("projects/#{@project_id}/pipelines/#{pipeline_id}/jobs")
    jobs = JSON.parse(response.body)

    job = jobs.find { |j| j['name'] == @job_name }

    if job.nil? || job['id'].nil?
      puts "Could not find #{@job_name} job in child pipeline. Skipping E2E #{@coverage_type} coverage export."
      return
    end

    job_id = job['id']
    puts "Found job ID: #{job_id}"
    job_id
  end

  def download_artifacts(job_id)
    puts "Downloading artifacts from job #{job_id}..."

    url = "#{@api_url}/projects/#{@project_id}/jobs/#{job_id}/artifacts"

    redirect_limit = 5
    redirect_count = 0
    success = false

    while redirect_count < redirect_limit && !success
      uri = URI(url)

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri)
        request['JOB-TOKEN'] = @job_token

        response = http.request(request)

        case response
        when Net::HTTPSuccess
          Tempfile.create(['artifacts', '.zip']) do |tempfile|
            tempfile.binmode
            tempfile.write(response.body)
            tempfile.flush

            puts "Extracting artifacts..."
            raise "Failed to extract artifacts" unless system('unzip', '-o', tempfile.path)
          end

          puts "Artifacts downloaded and extracted successfully"
          success = true
        when Net::HTTPRedirection
          redirect_count += 1
          url = response['location']
          puts "Following redirect to: #{url}"
        else
          raise "Failed to download artifacts: HTTP #{response.code}\n#{response.body}"
        end
      end
    end

    raise "Too many redirects (#{redirect_limit})" unless success
  end

  def api_request(endpoint)
    url = "#{@api_url}/#{endpoint}"
    uri = URI(url)

    request = Net::HTTP::Get.new(uri)
    request['JOB-TOKEN'] = @job_token

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    raise "API request failed: HTTP #{response.code}\n#{response.body}" unless response.code == '200'

    response
  end
end
