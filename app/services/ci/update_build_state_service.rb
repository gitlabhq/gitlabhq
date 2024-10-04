# frozen_string_literal: true

module Ci
  class UpdateBuildStateService
    include ::Gitlab::Utils::StrongMemoize
    include ::Gitlab::ExclusiveLeaseHelpers

    Result = Struct.new(:status, :backoff, keyword_init: true)
    InvalidTraceError = Class.new(StandardError)

    ACCEPT_TIMEOUT = 5.minutes.freeze

    attr_reader :build, :params, :metrics

    def initialize(build, params, metrics = ::Gitlab::Ci::Trace::Metrics.new)
      @build = build
      @params = params
      @metrics = metrics
    end

    def execute
      unless accept_available?
        return update_build_state!
      end

      ensure_pending_state!

      in_build_trace_lock do
        process_build_state!
      end
    end

    private

    def ensure_pending_state!
      pending_state.created_at
    end

    def process_build_state!
      if live_chunks_pending?
        if pending_state_outdated?
          discard_build_trace!
          update_build_state!
        else
          accept_build_state!
        end
      else
        validate_build_trace!
        update_build_state!
      end
    end

    def accept_build_state!
      build.trace_chunks.live.find_each do |chunk|
        chunk.schedule_to_persist!
      end

      metrics.increment_trace_operation(operation: :accepted)

      ::Gitlab::Ci::Runner::Backoff.new(pending_state.created_at).then do |backoff|
        Result.new(status: 202, backoff: backoff.to_seconds)
      end
    end

    def validate_build_trace!
      return unless has_chunks?

      unless live_chunks_pending?
        metrics.increment_trace_operation(operation: :finalized)
        metrics.observe_migration_duration(pending_state_seconds)
      end

      ::Gitlab::Ci::Trace::Checksum.new(build).then do |checksum|
        unless checksum.valid?
          metrics.increment_trace_operation(operation: :invalid)
          metrics.increment_error_counter(error_reason: :chunks_invalid_checksum)

          if checksum.corrupted?
            metrics.increment_trace_operation(operation: :corrupted)
            metrics.increment_error_counter(error_reason: :chunks_invalid_size)
          end

          next unless log_invalid_chunks?

          ::Gitlab::ErrorTracking.log_exception(InvalidTraceError.new,
            project_path: build.project.full_path,
            build_id: build.id,
            state_crc32: checksum.state_crc32,
            chunks_crc32: checksum.chunks_crc32,
            chunks_count: checksum.chunks_count,
            chunks_corrupted: checksum.corrupted?
          )
        end
      end
    end

    def update_build_state!
      case build_state
      when 'running'
        build.touch if build.needs_touch?

        Result.new(status: 200)
      when 'success'
        build.success!

        Result.new(status: 200)
      when 'failed'
        build.drop_with_exit_code!(params[:failure_reason], params[:exit_code])

        Result.new(status: 200)
      else
        Result.new(status: 400)
      end
    end

    def discard_build_trace!
      metrics.increment_trace_operation(operation: :discarded)
    end

    def accept_available?
      !build_running? && has_checksum? && chunks_migration_enabled?
    end

    def live_chunks_pending?
      build.trace_chunks.live.any?
    end

    def has_chunks?
      build.trace_chunks.any?
    end

    def pending_state_outdated?
      pending_state_duration > ACCEPT_TIMEOUT
    end

    def pending_state_duration
      Time.current - pending_state.created_at
    end

    def pending_state_seconds
      pending_state_duration.seconds
    end

    def build_state
      params[:state].to_s
    end

    def has_checksum?
      trace_checksum.present?
    end

    def build_running?
      build_state == 'running'
    end

    def trace_checksum
      params.dig(:output, :checksum) || params[:checksum]
    end

    def trace_bytesize
      params.dig(:output, :bytesize)
    end

    def pending_state
      strong_memoize(:pending_state) { ensure_pending_state }
    end

    def ensure_pending_state
      build_state = Ci::BuildPendingState.safe_find_or_create_by(
        build_id: build.id,
        partition_id: build.partition_id,
        state: params.fetch(:state),
        trace_checksum: trace_checksum,
        trace_bytesize: trace_bytesize,
        failure_reason: failure_reason
      )

      unless build_state.present?
        metrics.increment_trace_operation(operation: :conflict)
      end

      build_state || build.pending_state
    end

    def failure_reason
      reason = params[:failure_reason]

      return unless reason

      Ci::BuildPendingState.failure_reasons.fetch(reason.to_s, 'unknown_failure')
    end

    ##
    # This method is releasing an exclusive lock on a build trace the moment we
    # conclude that build status has been written and the build state update
    # has been committed to the database.
    #
    # Because a build state machine schedules a bunch of workers to run after
    # build status transition to complete, we do not want to keep the lease
    # until all the workers are scheduled because it opens a possibility of
    # race conditions happening.
    #
    # Instead of keeping the lease until the transition is fully done and
    # workers are scheduled, we immediately release the lock after the database
    # commit happens.
    #
    def in_build_trace_lock(&block)
      build.trace.lock do |_, lease| # rubocop:disable CodeReuse/ActiveRecord
        build.run_on_status_commit { lease.cancel }

        yield
      end
    rescue ::Gitlab::Ci::Trace::LockedError
      metrics.increment_trace_operation(operation: :locked)

      accept_build_state!
    end

    def chunks_migration_enabled?
      ::Feature.enabled?(:ci_enable_live_trace, build.project)
    end

    def log_invalid_chunks?
      ::Feature.enabled?(:ci_trace_log_invalid_chunks, build.project, type: :ops)
    end
  end
end
