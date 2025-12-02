#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'child_pipeline_artifact_downloader'

# Downloads E2E backend coverage artifacts from a child pipeline
# triggered by the e2e:test-on-gdk job.
if __FILE__ == $PROGRAM_NAME
  downloader = ChildPipelineArtifactDownloader.new(
    bridge_name: 'e2e:test-on-gdk',
    job_name: 'process-backend-coverage',
    coverage_type: 'backend'
  )

  begin
    downloader.run
  rescue StandardError => e
    puts "Warning: #{e.message}"
  end

  # Exit 0 even if artifacts not found (graceful skip)
  # This allows the parent job to continue without E2E coverage
  exit 0
end
