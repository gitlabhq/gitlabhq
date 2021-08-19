# frozen_string_literal: true

module Gitlab
  module Database
    module Transaction
      class Context
        attr_reader :context

        LOG_DEPTH_THRESHOLD = 8
        LOG_SAVEPOINTS_THRESHOLD = 32
        LOG_DURATION_S_THRESHOLD = 300
        LOG_THROTTLE_DURATION = 1

        def initialize
          @context = {}
        end

        def set_start_time
          @context[:start_time] = current_timestamp
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

        def set_depth(depth)
          @context[:depth] = [@context[:depth].to_i, depth].max
        end

        def track_sql(sql)
          (@context[:queries] ||= []).push(sql)
        end

        def duration
          return unless @context[:start_time].present?

          current_timestamp - @context[:start_time]
        end

        def depth_threshold_exceeded?
          @context[:depth].to_i > LOG_DEPTH_THRESHOLD
        end

        def savepoints_threshold_exceeded?
          @context[:savepoints].to_i > LOG_SAVEPOINTS_THRESHOLD
        end

        def duration_threshold_exceeded?
          duration.to_i > LOG_DURATION_S_THRESHOLD
        end

        def log_savepoints?
          depth_threshold_exceeded? || savepoints_threshold_exceeded?
        end

        def log_duration?
          duration_threshold_exceeded?
        end

        def should_log?
          !logged_already? && (log_savepoints? || log_duration?)
        end

        def commit
          log(:commit)
        end

        def rollback
          log(:rollback)
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
            sql: queries
          }

          application_info(attributes)
        end

        def application_info(attributes)
          Gitlab::AppJsonLogger.info(attributes)
        end
      end
    end
  end
end
