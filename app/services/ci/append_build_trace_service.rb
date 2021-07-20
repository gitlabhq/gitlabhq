# frozen_string_literal: true

module Ci
  class AppendBuildTraceService
    Result = Struct.new(:status, :stream_size, keyword_init: true)
    TraceRangeError = Class.new(StandardError)

    attr_reader :build, :params

    def initialize(build, params)
      @build = build
      @params = params
    end

    def execute(body_data)
      # TODO:
      # it seems that `Content-Range` as formatted by runner is wrong,
      # the `byte_end` should point to final byte, but it points byte+1
      # that means that we have to calculate end of body,
      # as we cannot use `content_length[1]`
      # Issue: https://gitlab.com/gitlab-org/gitlab-runner/issues/3275

      content_range = stream_range.split('-')
      body_start = content_range[0].to_i
      body_end = body_start + body_data.bytesize

      if trace_size_exceeded?(body_end)
        build.drop(:trace_size_exceeded)

        return Result.new(status: 403)
      end

      stream_size = build.trace.append(body_data, body_start)

      unless stream_size == body_end
        log_range_error(stream_size, body_end)

        return Result.new(status: 416, stream_size: stream_size)
      end

      Result.new(status: 202, stream_size: stream_size)
    end

    private

    delegate :project, to: :build

    def stream_range
      params.fetch(:content_range)
    end

    def log_range_error(stream_size, body_end)
      extra = {
        build_id: build.id,
        body_end: body_end,
        stream_size: stream_size,
        stream_class: stream_size.class,
        stream_range: stream_range
      }

      build.trace_chunks.last.try do |chunk|
        extra.merge!(
          chunk_index: chunk.chunk_index,
          chunk_store: chunk.data_store,
          chunks_count: build.trace_chunks.count
        )
      end

      ::Gitlab::ErrorTracking
        .log_exception(TraceRangeError.new, extra)
    end

    def trace_size_exceeded?(size)
      Feature.enabled?(:ci_jobs_trace_size_limit, project, default_enabled: :yaml) &&
        project.actual_limits.exceeded?(:ci_jobs_trace_size_limit, size / 1.megabyte)
    end
  end
end
