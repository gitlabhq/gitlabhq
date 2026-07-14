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

      if stale_status_read?(job)
        refresh_job_from_primary(job)

        return if Ci::HasStatus::EXECUTING_STATUSES.include?(job.status)
      end

      raise NotRunningJobError.new('Job is not running',
        job: job)
    end

    # A job token is only handed to the runner after the job transitions to
    # `running`, so observing a pre-execution status while authenticating
    # with the token means the job was read from a stale replica.
    #
    # Database load balancing sticking prevents the majority of stale reads:
    # while the Redis write-location key for the build exists, reads are
    # routed to a caught-up replica or fall back to the primary. However, the
    # key expires after 30 seconds (Sticking::EXPIRATION), and replicas may
    # lag longer than that before health checks evict them, so requests
    # arriving outside that window lose the protection and can very
    # occasionally read a stale status.
    def stale_status_read?(job)
      Ci::HasStatus::PRE_EXECUTION_STATUSES.include?(job.status) &&
        Feature.enabled?(:ci_job_token_auth_stale_read_retry, ::Project.actor_from_id(job.project_id))
    end

    def refresh_job_from_primary(job)
      ::Gitlab::Database::LoadBalancing::SessionMap
        .current(::Ci::Build.load_balancer)
        .use_primary!

      job.reset

      log_stale_read_retry(job)
    rescue ActiveRecord::RecordNotFound
      # The job was deleted since the replica read; fall through to the
      # NotRunningJobError raised by the caller.
    end

    def log_stale_read_retry(job)
      Gitlab::AppLogger.info({
        class: self.class,
        job_id: job.id,
        job_status: job.status,
        job_recovered: Ci::HasStatus::EXECUTING_STATUSES.include?(job.status),
        message: 'job token auth retried on primary after stale status read'
      }.merge(Gitlab::ApplicationContext.current))
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
