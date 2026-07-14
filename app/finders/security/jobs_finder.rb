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
      if instance_of?(Security::JobsFinder)
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

      find_jobs
    end

    private

    def find_jobs
      @pipeline.builds.with_secure_reports_from_config_options(@job_types)
    end

    def valid_job_types?(job_types)
      (job_types - self.class.allowed_job_types).empty?
    end
  end
end
