# frozen_string_literal: true
module Ci
  class AuthJobFinder
    AuthError = Class.new(StandardError)
    NotRunningJobError = Class.new(AuthError)
    ErasedJobError = Class.new(AuthError)
    DeletedProjectError = Class.new(AuthError)

    def initialize(token:)
      @token = token
    end

    def execute!
      find_job_by_token.tap do |job|
        next unless job

        validate_job!(job)

        if job.user && Feature.enabled?(:ci_scoped_job_token, job.project, default_enabled: :yaml)
          job.user.set_ci_job_token_scope!(job)
        end
      end
    end

    def execute
      execute!
    rescue AuthError
    end

    private

    attr_reader :token, :require_running, :raise_on_missing

    def find_job_by_token
      ::Ci::Build.find_by_token(token)
    end

    def validate_job!(job)
      validate_running_job!(job)
      validate_job_not_erased!(job)
      validate_project_presence!(job)

      true
    end

    def validate_running_job!(job)
      raise NotRunningJobError, 'Job is not running' unless job.running?
    end

    def validate_job_not_erased!(job)
      raise ErasedJobError, 'Job has been erased!' if job.erased?
    end

    def validate_project_presence!(job)
      if job.project.nil? || job.project.pending_delete?
        raise DeletedProjectError, 'Project has been deleted!'
      end
    end
  end
end
