# frozen_string_literal: true

module Gitlab
  module Database
    module Transaction
      class Context
        attr_reader :context

        LOG_SAVEPOINTS_THRESHOLD = 1                # 1 `SAVEPOINT` created in a transaction
        LOG_DURATION_S_THRESHOLD = 120              # transaction that is running for 2 minutes or longer
        LOG_EXTERNAL_HTTP_COUNT_THRESHOLD = 50      # 50 external HTTP requests executed within transaction
        LOG_EXTERNAL_HTTP_DURATION_S_THRESHOLD = 1  # 1 second spent in HTTP requests in total within transaction
        LOG_THROTTLE_DURATION = 1

        def initialize
          @context = {}
        end

        def set_start_time
          @context[:start_time] = current_timestamp
        end

        def set_depth(depth)
          @context[:depth] = [@context[:depth].to_i, depth].max
        end

        def increment_savepoints
          @context[:savepoints] = @context[:savepoints].to_i + 1
        end

        def increment_rollbacks
          @context[:rollbacks] = @context[:rollbacks].to_i + 1
        end

        def increment_releases
          @context[:releases] = @context[:releases].to_i + 1
        end

        def track_sql(sql)
          (@context[:queries] ||= []).push(sql)
        end

        def track_backtrace(backtrace)
          cleaned_backtrace = Gitlab::BacktraceCleaner.clean_backtrace(backtrace)
          (@context[:backtraces] ||= []).push(cleaned_backtrace)
        end

        def initialize_external_http_tracking
          @context[:external_http_count_start] = external_http_requests_count_total
          @context[:external_http_duration_start] = external_http_requests_duration_total
        end

        def duration
          return unless @context[:start_time].present?

          current_timestamp - @context[:start_time]
        end

        def savepoints_threshold_exceeded?
          @context[:savepoints].to_i >= LOG_SAVEPOINTS_THRESHOLD
        end

        def duration_threshold_exceeded?
          duration.to_i >= LOG_DURATION_S_THRESHOLD
        end

        def external_http_requests_threshold_exceeded?
          external_http_requests_count >= LOG_EXTERNAL_HTTP_COUNT_THRESHOLD ||
            external_http_requests_duration >= LOG_EXTERNAL_HTTP_DURATION_S_THRESHOLD
        end

        def should_log?
          return false if logged_already?

          savepoints_threshold_exceeded? || duration_threshold_exceeded? ||
            external_http_requests_threshold_exceeded?
        end

        def commit
          log(:commit)
        end

        def rollback
          log(:rollback)
        end

        def backtraces
          @context[:backtraces].to_a
        end

        def external_http_requests_count
          @requests_count ||= external_http_requests_count_total - @context[:external_http_count_start].to_i
        end

        def external_http_requests_duration
          @requests_duration ||= external_http_requests_duration_total - @context[:external_http_duration_start].to_f
        end

        private

        def queries
          @context[:queries].to_a.join("\n")
        end

        def current_timestamp
          ::Gitlab::Metrics::System.monotonic_time
        end

        def logged_already?
          return false if @context[:last_log_timestamp].nil?

          (current_timestamp - @context[:last_log_timestamp].to_i) < LOG_THROTTLE_DURATION
        end

        def set_last_log_timestamp
          @context[:last_log_timestamp] = current_timestamp
        end

        def log(operation)
          return unless should_log?

          set_last_log_timestamp

          attributes = {
            class: self.class.name,
            result: operation,
            duration_s: duration,
            depth: @context[:depth].to_i,
            savepoints_count: @context[:savepoints].to_i,
            rollbacks_count: @context[:rollbacks].to_i,
            releases_count: @context[:releases].to_i,
            external_http_requests_count: external_http_requests_count,
            external_http_requests_duration: external_http_requests_duration,
            sql: queries,
            savepoint_backtraces: backtraces
          }

          application_info(attributes)
        end

        def application_info(attributes)
          Gitlab::AppJsonLogger.info(attributes)
        end

        def external_http_requests_count_total
          ::Gitlab::Metrics::Subscribers::ExternalHttp.request_count.to_i
        end

        def external_http_requests_duration_total
          ::Gitlab::Metrics::Subscribers::ExternalHttp.duration.to_f
        end
      end
    end
  end
end
