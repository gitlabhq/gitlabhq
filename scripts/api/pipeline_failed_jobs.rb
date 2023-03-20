# frozen_string_literal: true

require_relative 'base'

class PipelineFailedJobs < Base
  def initialize(options)
    super
    @pipeline_id = options.delete(:pipeline_id)
    @exclude_allowed_to_fail_jobs = options.delete(:exclude_allowed_to_fail_jobs)
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

  attr_reader :pipeline_id, :exclude_allowed_to_fail_jobs
end
