#!/usr/bin/env ruby

# frozen_string_literal: true

require 'gitlab'
require 'optparse'

require_relative 'api/default_options'

class CheckDefaultPipelineStatus
  def initialize(options)
    @options = options
    @project = @options.fetch(:project)
    api_token = @options.fetch(:api_token, '')

    warn "No API token given." if api_token.empty?

    @api_client = ::Gitlab.client(
      endpoint: options.fetch(:endpoint),
      private_token: api_token
    )
  end

  def execute
    return unless last_completed_default_pipeline&.status == 'failed' && jobs_expected_to_fail.any?

    warn error_message

    exit 1
  end

  private

  attr_reader :project, :api_client, :options

  def last_completed_default_pipeline
    @last_completed_default_pipeline ||= api_client.pipelines(
      project,
      ref: 'master',
      scope: 'finished',
      per_page: 1
    ).first
  end

  def jobs_expected_to_fail
    @jobs_expected_to_fail ||= failed_jobs_from_last_completed_default_pipeline.select do |failed_job|
      !failed_job.allow_failure && job_names_in_current_pipeline.include?(failed_job.name)
    end
  end

  def failed_jobs_from_last_completed_default_pipeline
    @failed_jobs_from_last_completed_default_pipeline ||= api_client.pipeline_jobs(
      project,
      last_completed_default_pipeline.id,
      scope: 'failed'
    ).auto_paginate
  end

  def job_names_in_current_pipeline
    @job_names_in_current_pipeline ||= begin
      jobs = api_client.pipeline_jobs(
        project,
        current_pipeline_id
      ).auto_paginate

      jobs.map(&:name)
    end
  end

  def current_pipeline_id
    ENV['CI_PIPELINE_ID']
  end

  def error_message
    <<~TEXT
      ******************************************************************************************
      We are failing this job to warn you that you may be impacted by a master broken incident.
      Jobs below may fail in your pipeline:
      #{jobs_expected_to_fail.map(&:name).join("\n")}
      Check if the failures are also present in the master pipeline: #{last_completed_default_pipeline&.web_url}
      Reach out to #master-broken for assistance if you think you are blocked.
      Apply ~"pipeline:ignore-master-status" to skip this job if you don't think this is helpful.
      ******************************************************************************************
    TEXT
  end
end

if $PROGRAM_NAME == __FILE__
  OptionParser.new do |opts|
    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  CheckDefaultPipelineStatus.new(API::DEFAULT_OPTIONS).execute
end
