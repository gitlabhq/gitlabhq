#!/usr/bin/env ruby
# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
require 'gitlab'
require 'fileutils'
require 'tempfile'

# Downloads artifacts from child pipelines.
#
# This workaround is needed because GitLab CI doesn't yet provide a direct way
# to access artifacts from child pipelines. See:
# - https://gitlab.com/gitlab-org/gitlab/-/issues/285100 (Allow job in upstream pipeline to reference artifacts)
# - https://gitlab.com/groups/gitlab-org/-/epics/8205 (Read child pipeline artifacts for MR reports)
class ChildPipelineArtifactDownloader
  def initialize
    @project_id = ENV.fetch('CI_PROJECT_ID')
    @pipeline_id = ENV.fetch('CI_PIPELINE_ID')

    @client = Gitlab.client(
      endpoint: ENV.fetch('CI_API_V4_URL'),
      private_token: ENV.fetch('CI_JOB_TOKEN')
    )
  end

  def run
    return unless child_pipeline_id

    job_id = find_job_id(child_pipeline_id, 'process-backend-coverage')
    return unless job_id

    download_artifacts(job_id)
  end

  private

  def child_pipeline_id
    return @child_pipeline_id if defined?(@child_pipeline_id)

    puts "Finding child pipeline ID from e2e:test-on-gdk trigger job..."

    bridge = pipeline_bridges.find { |b| b.name == 'e2e:test-on-gdk' }

    if bridge.nil? || bridge.downstream_pipeline.nil?
      puts "Could not find child pipeline ID. Skipping E2E backend coverage export."
      @child_pipeline_id = nil
      return
    end

    puts "Child pipeline ID: #{bridge.downstream_pipeline.id}"
    @child_pipeline_id = bridge.downstream_pipeline.id
  end

  def pipeline_bridges
    @pipeline_bridges ||= @client.pipeline_bridges(@project_id, @pipeline_id).auto_paginate
  end

  def find_job_id(pipeline_id, job_name)
    puts "Finding #{job_name} job in child pipeline..."

    job = pipeline_jobs(pipeline_id).find { |j| j.name == job_name }

    if job.nil?
      puts "Could not find #{job_name} job in child pipeline. Skipping E2E backend coverage export."
      return
    end

    puts "Found job ID: #{job.id}"
    job.id
  end

  def pipeline_jobs(pipeline_id)
    @pipeline_jobs ||= {}
    @pipeline_jobs[pipeline_id] ||= @client.pipeline_jobs(@project_id, pipeline_id).auto_paginate
  end

  def download_artifacts(job_id)
    puts "Downloading artifacts from job #{job_id}..."

    temp_file = Tempfile.new(['artifacts', '.zip'])
    temp_file.binmode

    begin
      artifact_data = @client.download_job_artifact_file(@project_id, job_id)
      temp_file.write(artifact_data)
      temp_file.close

      puts "Extracting artifacts..."

      unless system('unzip', '-o', temp_file.path)
        puts "ERROR: Failed to extract artifacts"
        exit 1
      end

      puts "Artifacts downloaded and extracted successfully"
    ensure
      temp_file.close unless temp_file.closed?
      temp_file.unlink
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  downloader = ChildPipelineArtifactDownloader.new
  downloader.run

  # Exit 0 even if artifacts not found (graceful skip)
  # This allows the parent job to continue without E2E coverage
  exit 0
end
