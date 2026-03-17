#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'child_pipeline_artifact_downloader'

# Downloads all E2E artifacts (coverage + test reports + test mappings) from a child pipeline
# triggered by the e2e:test-on-gdk job.
#
# The artifacts downloaded include:
# - coverage-e2e-backend/ (Coverband coverage files)
# - coverage-e2e-frontend/ (Istanbul coverage + test mappings)
# - e2e-test-reports/ (RSpec JSON reports with feature_category metadata)
if __FILE__ == $PROGRAM_NAME
  BRIDGE_NAME = ENV.fetch('BRIDGE_NAME', 'e2e:test-on-gdk')
  JOB_NAME = ENV.fetch('JOB_NAME', nil)
  COVERAGE_TYPE = ENV.fetch('COVERAGE_TYPE', 'e2e-artifacts')

  downloader = ChildPipelineArtifactDownloader.new(
    bridge_name: BRIDGE_NAME,
    job_name: JOB_NAME,
    coverage_type: COVERAGE_TYPE
  )

  begin
    downloader.run
  rescue StandardError => e
    puts "Warning: #{e.message}"
  end

  # Exit 0 even if artifacts not found (graceful skip)
  # This allows the parent job to continue without E2E artifacts
  exit 0
end
