# frozen_string_literal: true

# Security::JobsFinder
#
# Abstract class encapsulating common logic for finding jobs (builds) that are related to the Secure products
# SAST, DAST, Dependency Scanning, Container Scanning and License Management, Coverage Fuzzing
#
# Arguments:
#   params:
#     pipeline:              required, only jobs for the specified pipeline will be found
#     job_types:             required, array of job types that should be returned, defaults to all job types

module Security
  class JobsFinder
    attr_reader :pipeline

    def self.allowed_job_types
      # Example return: [:sast, :dast, :dependency_scanning, :container_scanning, :license_scanning, :coverage_fuzzing]
      raise NotImplementedError, 'allowed_job_types must be overwritten to return an array of job types'
    end

    def initialize(pipeline:, job_types: [])
      if self.class == Security::JobsFinder
        raise NotImplementedError, 'This is an abstract class, please instantiate its descendants'
      end

      if job_types.empty?
        @job_types = self.class.allowed_job_types
      elsif valid_job_types?(job_types)
        @job_types = job_types
      else
        raise ArgumentError, "job_types must be from the following: #{self.class.allowed_job_types}"
      end

      @pipeline = pipeline
    end

    def execute
      return [] if @job_types.empty?

      if Feature.enabled?(:ci_build_metadata_config, pipeline.project, default_enabled: :yaml)
        find_jobs
      else
        find_jobs_legacy
      end
    end

    private

    def find_jobs
      @pipeline.builds.with_secure_reports_from_config_options(@job_types)
    end

    def find_jobs_legacy
      # the query doesn't guarantee accuracy, so we verify it here
      legacy_jobs_query.select do |job|
        @job_types.find { |job_type| job.options.dig(:artifacts, :reports, job_type) }
      end
    end

    def legacy_jobs_query
      @job_types.map do |job_type|
        @pipeline.builds.with_secure_reports_from_options(job_type)
      end.reduce(&:or)
    end

    def valid_job_types?(job_types)
      (job_types - self.class.allowed_job_types).empty?
    end
  end
end
