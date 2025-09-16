# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      # Handle a Sidekiq job payload limit based on current configuration.
      # This validator pulls the configuration from application settings:
      # - limiter_mode: the current mode of the size
      #   limiter. This must be either `track` or `compress`.
      # - compression_threshold_bytes: the threshold before the input job
      #   payload is compressed.
      # - limit_bytes: the size limit in bytes.
      #
      # In track mode, if a job payload limit exceeds the size limit, an
      # event is sent to Sentry and the job is scheduled like normal.
      #
      # In compress mode, if a job payload limit exceeds the threshold, it is
      # then compressed. If the compressed payload still exceeds the limit, the
      # job is discarded, and a ExceedLimitError exception is raised.
      class Validator
        # Avoid limiting the size of jobs for `BatchedBackgroundMigrationWorker` classes.
        # We can't read the configuration from `ApplicationSetting` for those jobs
        # when migrating a path that modifies the `application_settings` table.
        # Reading the application settings through `ApplicationSetting#current`
        # causes a `SELECT` with a list of column names, but that list of column
        # names might not match what the table currently looks like causing
        # an error when scheduling background migrations.
        #
        # The worker classes aren't constants here, because that would force
        # Application Settings to be loaded earlier causing failures loading
        # the environment in rake tasks

        EXEMPT_WORKER_NAMES = %w[
          Database::BatchedBackgroundMigrationWorker
          Database::BatchedBackgroundMigration::CiDatabaseWorker
          Database::BatchedBackgroundMigration::SecDatabaseWorker
          RedisMigrationWorker
        ].to_set

        JOB_STATUS_KEY = 'size_limiter'

        class << self
          def validate!(worker_class, job)
            return if EXEMPT_WORKER_NAMES.include?(worker_class.to_s)
            return if validated?(job)

            new(worker_class, job).validate!
          end

          def validated?(job)
            job.has_key?(JOB_STATUS_KEY)
          end
        end

        DEFAULT_SIZE_LIMIT = 0
        DEFAULT_COMPRESSION_THRESHOLD_BYTES = 100_000 # 100kb

        MODES = [
          TRACK_MODE = 'track',
          COMPRESS_MODE = 'compress'
        ].freeze

        attr_reader :mode, :size_limit, :compression_threshold

        def initialize(worker_class, job)
          @worker_class = worker_class
          @job = job

          current_settings = Gitlab::CurrentSettings.current_application_settings

          @mode = current_settings.sidekiq_job_limiter_mode
          @compression_threshold = current_settings.sidekiq_job_limiter_compression_threshold_bytes
          @size_limit = current_settings.sidekiq_job_limiter_limit_bytes
        end

        def validate!
          @job[JOB_STATUS_KEY] = 'validated'

          job_args = compress_if_necessary(::Sidekiq.dump_json(@job['args']))

          return if @size_limit == 0
          return if job_args.bytesize <= @size_limit
          return if allow_big_payload?

          exception = exceed_limit_error(job_args)
          if compress_mode?
            @job.delete(JOB_STATUS_KEY)
            raise exception
          else
            @job[JOB_STATUS_KEY] = 'tracked'
            track(exception)
          end
        end

        private

        def exceed_limit_error(job_args)
          ExceedLimitError.new(@worker_class, job_args.bytesize, @size_limit).tap do |exception|
            # This should belong to Gitlab::ErrorTracking. We'll remove this
            # after this epic is done:
            # https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/396
            exception.set_backtrace(backtrace)
          end
        end

        def compress_if_necessary(job_args)
          return job_args unless compress_mode?
          return job_args if job_args.bytesize < @compression_threshold

          # When a job was scheduled in the future, it runs through the middleware
          # twice. Once on scheduling and once on queueing. No need to compress twice.
          return job_args if ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor.compressed?(@job)

          ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor.compress(@job, job_args)
        end

        def allow_big_payload?
          worker_class = @worker_class.to_s.safe_constantize
          worker_class.respond_to?(:big_payload?) && worker_class.big_payload?
        end

        def compress_mode?
          @mode == COMPRESS_MODE
        end

        def track(exception)
          Gitlab::ErrorTracking.track_exception(exception)
        end

        def backtrace
          Gitlab::BacktraceCleaner.clean_backtrace(caller)
        end
      end
    end
  end
end
