#!/usr/bin/env ruby

# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'

require_relative 'api/default_options'

# This class allows an upstream job to fetch an artifact from a job in a downstream pipeline.
#
# Until https://gitlab.com/gitlab-org/gitlab/-/issues/285100 is resolved it's not straightforward for an upstream
# pipeline to use artifacts from a downstream pipeline. There is a workaround for parent-child pipelines (see the issue)
# but it relies on CI_MERGE_REQUEST_REF_PATH so it doesn't work for multi-project pipelines.
#
# This uses the Jobs API to get pipeline bridges (trigger jobs) and the Job artifacts API to download artifacts.
# - https://docs.gitlab.com/ee/api/jobs.html#list-pipeline-trigger-jobs
# - https://docs.gitlab.com/ee/api/job_artifacts.html
#
# Note: This class also works for parent-child pipelines within the same project, it's just not necessary in that case.
class DownloadDownstreamArtifact
  def initialize(options)
    @upstream_project = options.fetch(:upstream_project, API::DEFAULT_OPTIONS[:project])
    @upstream_pipeline_id = options.fetch(:upstream_pipeline_id, API::DEFAULT_OPTIONS[:pipeline_id])
    @downstream_project = options.fetch(:downstream_project, API::DEFAULT_OPTIONS[:project])
    @downstream_job_name = options.fetch(:downstream_job_name)
    @trigger_job_name = options.fetch(:trigger_job_name)
    @downstream_artifact_path = options.fetch(:downstream_artifact_path)
    @output_artifact_path = options.fetch(:output_artifact_path)

    unless options.key?(:api_token)
      raise ArgumentError, 'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE is required to access downstream pipelines'
    end

    api_token = options.fetch(:api_token)

    @client = Gitlab.client(
      endpoint: options.fetch(:endpoint, API::DEFAULT_OPTIONS[:endpoint]),
      private_token: api_token
    )
  end

  def execute
    unless downstream_pipeline
      abort("Could not find downstream pipeline triggered via #{trigger_job_name} in project #{downstream_project}")
    end

    unless downstream_job
      abort("Could not find job with name '#{downstream_job_name}' in #{downstream_pipeline['web_url']}")
    end

    puts "Fetching scores artifact from downstream pipeline triggered via #{trigger_job_name}..."
    puts "Downstream pipeline is #{downstream_pipeline['web_url']}."
    puts %(Downstream job "#{downstream_job_name}": #{downstream_job['web_url']}.)

    path = downstream_artifact_path.sub('DOWNSTREAM_JOB_ID', downstream_job.id.to_s)
    puts %(Fetching artifact "#{path}" from #{downstream_job_name}...)

    download_and_save_artifact(path)

    puts "Artifact saved as #{output_artifact_path} ..."
  end

  def self.options_from_env
    API::DEFAULT_OPTIONS.merge({
      upstream_project: API::DEFAULT_OPTIONS[:project],
      upstream_pipeline_id: API::DEFAULT_OPTIONS[:pipeline_id],
      downstream_project: ENV.fetch('DOWNSTREAM_PROJECT', API::DEFAULT_OPTIONS[:project]),
      downstream_job_name: ENV['DOWNSTREAM_JOB_NAME'],
      trigger_job_name: ENV['TRIGGER_JOB_NAME'],
      downstream_artifact_path: ENV['DOWNSTREAM_JOB_ARTIFACT_PATH'],
      output_artifact_path: ENV['OUTPUT_ARTIFACT_PATH']
    }).except(:project, :pipeline_id)
  end

  private

  attr_reader :downstream_artifact_path,
    :output_artifact_path,
    :downstream_job_name,
    :trigger_job_name,
    :upstream_project,
    :downstream_project,
    :upstream_pipeline_id,
    :client

  def bridge
    @bridge ||= client
      .pipeline_bridges(upstream_project, upstream_pipeline_id, per_page: 100)
      .auto_paginate
      .find { |job| job.name.include?(trigger_job_name) }
  end

  def downstream_pipeline
    @downstream_pipeline ||=
      if bridge&.downstream_pipeline.nil?
        nil
      else
        client.pipeline(downstream_project, bridge.downstream_pipeline.id)
      end
  end

  def downstream_job
    @downstream_job ||= client
      .pipeline_jobs(downstream_project, downstream_pipeline.id)
      .find { |job| job.name.include?(downstream_job_name) }
  end

  def download_and_save_artifact(job_artifact_path)
    file_response = client.download_job_artifact_file(downstream_project, downstream_job.id, job_artifact_path)

    file_response.respond_to?(:read) || abort("Could not download artifact. Request returned: #{file_response}")

    File.write(output_artifact_path, file_response.read)
  end
end

if $PROGRAM_NAME == __FILE__
  options = DownloadDownstreamArtifact.options_from_env

  DownloadDownstreamArtifact.new(options).execute
end
