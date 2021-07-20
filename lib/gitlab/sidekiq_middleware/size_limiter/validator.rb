# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module SizeLimiter
      # Handle a Sidekiq job payload limit based on current configuration.
      # This validator pulls the configuration from the environment variables:
      # - GITLAB_SIDEKIQ_SIZE_LIMITER_MODE: the current mode of the size
      # limiter. This must be either `track` or `compress`.
      # - GITLAB_SIDEKIQ_SIZE_LIMITER_COMPRESSION_THRESHOLD_BYTES: the
      # threshold before the input job payload is compressed.
      # - GITLAB_SIDEKIQ_SIZE_LIMITER_LIMIT_BYTES: the size limit in bytes.
      #
      # In track mode, if a job payload limit exceeds the size limit, an
      # event is sent to Sentry and the job is scheduled like normal.
      #
      # In compress mode, if a job payload limit exceeds the threshold, it is
      # then compressed. If the compressed payload still exceeds the limit, the
      # job is discarded, and a ExceedLimitError exception is raised.
      class Validator
        def self.validate!(worker_class, job)
          new(worker_class, job).validate!
        end

        DEFAULT_SIZE_LIMIT = 0
        DEFAULT_COMPRESION_THRESHOLD_BYTES = 100_000 # 100kb

        MODES = [
          TRACK_MODE = 'track',
          COMPRESS_MODE = 'compress'
        ].freeze

        attr_reader :mode, :size_limit, :compression_threshold

        def initialize(
          worker_class, job,
          mode: ENV['GITLAB_SIDEKIQ_SIZE_LIMITER_MODE'],
          compression_threshold: ENV['GITLAB_SIDEKIQ_SIZE_LIMITER_COMPRESSION_THRESHOLD_BYTES'],
          size_limit: ENV['GITLAB_SIDEKIQ_SIZE_LIMITER_LIMIT_BYTES']
        )
          @worker_class = worker_class
          @job = job

          set_mode(mode)
          set_compression_threshold(compression_threshold)
          set_size_limit(size_limit)
        end

        def validate!
          return unless @size_limit > 0
          return if allow_big_payload?

          job_args = compress_if_necessary(::Sidekiq.dump_json(@job['args']))
          return if job_args.bytesize <= @size_limit

          exception = exceed_limit_error(job_args)
          if compress_mode?
            raise exception
          else
            track(exception)
          end
        end

        private

        def set_mode(mode)
          @mode = (mode || TRACK_MODE).to_s.strip
          unless MODES.include?(@mode)
            ::Sidekiq.logger.warn "Invalid Sidekiq size limiter mode: #{@mode}. Fallback to #{TRACK_MODE} mode."
            @mode = TRACK_MODE
          end
        end

        def set_compression_threshold(compression_threshold)
          @compression_threshold = (compression_threshold || DEFAULT_COMPRESION_THRESHOLD_BYTES).to_i
          if @compression_threshold <= 0
            ::Sidekiq.logger.warn "Invalid Sidekiq size limiter compression threshold: #{@compression_threshold}"
            @compression_threshold = DEFAULT_COMPRESION_THRESHOLD_BYTES
          end
        end

        def set_size_limit(size_limit)
          @size_limit = (size_limit || DEFAULT_SIZE_LIMIT).to_i
          if @size_limit < 0
            ::Sidekiq.logger.warn "Invalid Sidekiq size limiter limit: #{@size_limit}"
          end
        end

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
