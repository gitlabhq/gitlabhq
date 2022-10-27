# frozen_string_literal: true

require 'gitlab'

require_relative 'default_options'

class PipelineFailedJobs
  def initialize(options)
    @project = options.delete(:project)
    @pipeline_id = options.delete(:pipeline_id)
    @exclude_allowed_to_fail_jobs = options.delete(:exclude_allowed_to_fail_jobs)

    # Force the token to be a string so that if api_token is nil, it's set to '',
    # allowing unauthenticated requests (for forks).
    api_token = options.delete(:api_token).to_s

    warn "No API token given." if api_token.empty?

    @client = Gitlab.client(
      endpoint: options.delete(:endpoint) || API::DEFAULT_OPTIONS[:endpoint],
      private_token: api_token
    )
  end

  def execute
    failed_jobs = []

    client.pipeline_jobs(project, pipeline_id, scope: 'failed', per_page: 100).auto_paginate do |job|
      next if exclude_allowed_to_fail_jobs && job.allow_failure

      failed_jobs << job
    end

    client.pipeline_bridges(project, pipeline_id, scope: 'failed', per_page: 100).auto_paginate do |job|
      next if exclude_allowed_to_fail_jobs && job.allow_failure

      job.web_url = job.downstream_pipeline.web_url # job.web_url is linking to an invalid page
      failed_jobs << job
    end

    failed_jobs
  end

  private

  attr_reader :project, :pipeline_id, :exclude_allowed_to_fail_jobs, :client
end
