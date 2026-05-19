# frozen_string_literal: true

module Ci
  class AuthJobFinder
    class AuthError < StandardError
      attr_reader :job

      def initialize(message, job:)
        super(message)
        @job = job
      end
    end

    NotRunningJobError = Class.new(AuthError)
    ErasedJobError = Class.new(AuthError)
    DeletedProjectError = Class.new(AuthError)
    ExpiredJobTokenError = Class.new(AuthError)

    MAX_TOKEN_BYTESIZE = ::Gitlab::Auth::AuthFinders::MAX_JOB_TOKEN_SIZE_BYTES

    def initialize(token:)
      @token = token
    end

    def execute!
      find_job_by_token.tap do |job|
        next unless job

        validate_job!(job)

        job.user.set_ci_job_token_scope!(job) if job.user
      end
    end

    def execute
      execute!
    rescue AuthError
    end

    private

    attr_reader :token

    def find_job_by_token
      return if token.bytesize > MAX_TOKEN_BYTESIZE

      # TODO: Remove fallback finder when feature flag `ci_job_token_jwt` is removed
      find_job_by_jwt || find_from_database_token
    end

    def find_job_by_jwt
      # Intentionally bypass JWT expiration verification to recover the job identity.
      # Expiration is checked separately via `jwt.expired?`.
      jwt = ::Ci::JobToken::Jwt.decode(token, verify_expiration: false)
      return unless jwt&.job

      raise ExpiredJobTokenError.new('Job token has expired', job: jwt.job) if jwt.expired?

      link_composite_identity!(jwt)
      jwt.job
    end

    def link_composite_identity!(jwt)
      return unless jwt.scoped_user

      # We prefer not to use `link_from_job` when we have the JWT because
      # the JWT is the source of truth.
      ::Gitlab::Auth::Identity.fabricate(jwt.job.user)&.link!(jwt.scoped_user)
    end

    def find_from_database_token
      return unless ::Authn::Tokens::CiJobToken.prefix?(token)

      ::Ci::Build.find_by_token(token)
    end

    def validate_job!(job)
      validate_executing_job!(job)
      validate_job_not_erased!(job)
      validate_project_presence!(job)

      log_successful_job_auth(job)

      true
    end

    def validate_executing_job!(job)
      return if Ci::HasStatus::EXECUTING_STATUSES.include?(job.status)

      raise NotRunningJobError.new('Job is not running',
        job: job)
    end

    def validate_job_not_erased!(job)
      raise ErasedJobError.new('Job has been erased!', job: job) if job.erased?
    end

    def validate_project_presence!(job)
      return unless job.project.nil? || job.project.pending_delete?

      raise DeletedProjectError.new('Project has been deleted!',
        job: job)
    end

    def log_successful_job_auth(job)
      Gitlab::AppLogger.info({
        class: self.class,
        job_id: job.id,
        job_user_id: job.user_id,
        job_project_id: job.project_id,
        message: "successful job token auth"
      }.merge(Gitlab::ApplicationContext.current))
    end
  end
end
