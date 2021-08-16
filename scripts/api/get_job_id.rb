#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'optparse'
require_relative 'default_options'

class JobFinder
  DEFAULT_OPTIONS = API::DEFAULT_OPTIONS.merge(
    pipeline_query: {}.freeze,
    job_query: {}.freeze
  ).freeze

  def initialize(options)
    @project = options.delete(:project)
    @pipeline_query = options.delete(:pipeline_query) || DEFAULT_OPTIONS[:pipeline_query]
    @job_query = options.delete(:job_query) || DEFAULT_OPTIONS[:job_query]
    @pipeline_id = options.delete(:pipeline_id)
    @job_name = options.delete(:job_name)
    @artifact_path = options.delete(:artifact_path)

    # Force the token to be a string so that if api_token is nil, it's set to '', allowing unauthenticated requests (for forks).
    api_token = options.delete(:api_token).to_s

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.delete(:endpoint) || DEFAULT_OPTIONS[:endpoint],
      private_token: api_token
    )
  end

  def execute
    find_job_with_artifact || find_job_with_filtered_pipelines || find_job_in_pipeline
  end

  private

  attr_reader :project, :pipeline_query, :job_query, :pipeline_id, :job_name, :artifact_path, :client

  def find_job_with_artifact
    return if artifact_path.nil?

    client.pipelines(project, pipeline_query_params).auto_paginate do |pipeline|
      client.pipeline_jobs(project, pipeline.id, job_query_params).auto_paginate do |job|
        return job if found_job_with_artifact?(job) # rubocop:disable Cop/AvoidReturnFromBlocks
      end
    end

    raise 'Job not found!'
  end

  def find_job_with_filtered_pipelines
    return if pipeline_query.empty?

    client.pipelines(project, pipeline_query_params).auto_paginate do |pipeline|
      client.pipeline_jobs(project, pipeline.id, job_query_params).auto_paginate do |job|
        return job if found_job_by_name?(job) # rubocop:disable Cop/AvoidReturnFromBlocks
      end
    end

    raise 'Job not found!'
  end

  def find_job_in_pipeline
    return unless pipeline_id

    client.pipeline_jobs(project, pipeline_id, job_query_params).auto_paginate do |job|
      return job if found_job_by_name?(job) # rubocop:disable Cop/AvoidReturnFromBlocks
    end

    raise 'Job not found!'
  end

  def found_job_with_artifact?(job)
    artifact_url = "#{client.endpoint}/projects/#{CGI.escape(project)}/jobs/#{job.id}/artifacts/#{artifact_path}"
    response = HTTParty.head(artifact_url) # rubocop:disable Gitlab/HTTParty
    response.success?
  end

  def found_job_by_name?(job)
    job.name == job_name
  end

  def pipeline_query_params
    @pipeline_query_params ||= { per_page: 100, **pipeline_query }
  end

  def job_query_params
    @job_query_params ||= { per_page: 100, **job_query }
  end
end

if $0 == __FILE__
  options = JobFinder::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-p", "--project PROJECT", String, "Project where to find the job (defaults to $CI_PROJECT_ID)") do |value|
      options[:project] = value
    end

    opts.on("-i", "--pipeline-id pipeline_id", String, "A pipeline ID (defaults to $CI_PIPELINE_ID)") do |value|
      options[:pipeline_id] = value
    end

    opts.on("-q", "--pipeline-query pipeline_query", String, "Query to pass to the Pipeline API request") do |value|
      options[:pipeline_query] =
        options[:pipeline_query].merge(Hash[*value.split('=')])
    end

    opts.on("-Q", "--job-query job_query", String, "Query to pass to the Job API request") do |value|
      options[:job_query] =
        options[:job_query].merge(Hash[*value.split('=')])
    end

    opts.on("-j", "--job-name job_name", String, "A job name that needs to exist in the found pipeline") do |value|
      options[:job_name] = value
    end

    opts.on("-a", "--artifact-path ARTIFACT_PATH", String, "A valid artifact path") do |value|
      options[:artifact_path] = value
    end

    opts.on("-t", "--api-token API_TOKEN", String, "A value API token with the `read_api` scope") do |value|
      options[:api_token] = value
    end

    opts.on("-E", "--endpoint ENDPOINT", String, "The API endpoint for the API token. (defaults to $CI_API_V4_URL and fallback to https://gitlab.com/api/v4)") do |value|
      options[:endpoint] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  job = JobFinder.new(options).execute

  return if job.nil?

  puts job.id
end
