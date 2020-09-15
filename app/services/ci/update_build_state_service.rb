# frozen_string_literal: true

module Ci
  class UpdateBuildStateService
    Result = Struct.new(:status, keyword_init: true)

    ACCEPT_TIMEOUT = 5.minutes.freeze

    attr_reader :build, :params, :metrics

    def initialize(build, params, metrics = ::Gitlab::Ci::Trace::Metrics.new)
      @build = build
      @params = params
      @metrics = metrics
    end

    def execute
      overwrite_trace! if has_trace?

      if accept_request?
        accept_build_state!
      else
        check_migration_state
        update_build_state!
      end
    end

    private

    def accept_build_state!
      if Time.current - ensure_pending_state.created_at > ACCEPT_TIMEOUT
        metrics.increment_trace_operation(operation: :discarded)

        return update_build_state!
      end

      build.trace_chunks.live.find_each do |chunk|
        chunk.schedule_to_persist!
      end

      metrics.increment_trace_operation(operation: :accepted)

      Result.new(status: 202)
    end

    def overwrite_trace!
      metrics.increment_trace_operation(operation: :overwrite)

      build.trace.set(params[:trace]) if Gitlab::Ci::Features.trace_overwrite?
    end

    def check_migration_state
      return unless accept_available?

      if has_chunks? && !live_chunks_pending?
        metrics.increment_trace_operation(operation: :finalized)
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
        build.drop!(params[:failure_reason] || :unknown_failure)

        Result.new(status: 200)
      else
        Result.new(status: 400)
      end
    end

    def accept_available?
      !build_running? && has_checksum? && chunks_migration_enabled?
    end

    def accept_request?
      accept_available? && live_chunks_pending?
    end

    def build_state
      params.dig(:state).to_s
    end

    def has_trace?
      params.dig(:trace).present?
    end

    def has_checksum?
      params.dig(:checksum).present?
    end

    def has_chunks?
      build.trace_chunks.any?
    end

    def live_chunks_pending?
      build.trace_chunks.live.any?
    end

    def build_running?
      build_state == 'running'
    end

    def ensure_pending_state
      Ci::BuildPendingState.create_or_find_by!(
        build_id: build.id,
        state: params.fetch(:state),
        trace_checksum: params.fetch(:checksum),
        failure_reason: params.dig(:failure_reason)
      )
    rescue ActiveRecord::RecordNotFound
      metrics.increment_trace_operation(operation: :conflict)

      build.pending_state
    end

    def chunks_migration_enabled?
      ::Gitlab::Ci::Features.accept_trace?(build.project)
    end
  end
end
