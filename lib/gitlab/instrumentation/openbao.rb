# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Openbao
      REQUEST_COUNT = :openbao_request_count
      CALL_DURATION = :openbao_call_duration

      DURATION_BUCKETS = [0.001, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.0, 5.0].freeze

      # OpenBao paths embed the namespace, mount and secret name, all of which
      # derive from project and group IDs. Only a value from these three lists
      # ever reaches a metric label.
      SYS_ENDPOINTS = %w[namespaces mounts auth policies capabilities-self health rotate].freeze
      AUTH_ENDPOINTS = %w[login role config revoke-self].freeze
      KV_SEGMENTS = %w[data metadata detailed-metadata].freeze

      STRUCTURAL_SEGMENTS = (%w[sys auth] + KV_SEGMENTS).freeze

      class << self
        def get_request_count
          ::Gitlab::SafeRequestStore[REQUEST_COUNT] || 0
        end

        def query_time
          call_duration.round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
        end

        def add_call(duration:, path:, method:, outcome:, error_type: nil)
          # Outside a request (cron, rake) the store is a null object that
          # drops writes, so reading a counter back returns nil. The Prometheus
          # metrics below still work there and are the point of this method.
          if ::Gitlab::SafeRequestStore.active?
            increment_request_count
            add_duration(duration)
          end

          operation = operation_for(path)

          requests_total.increment(operation: operation, method: method.to_s, outcome: outcome.to_s)
          request_duration_seconds.observe({ operation: operation, outcome: outcome.to_s }, duration)

          return unless error_type

          request_errors_total.increment(operation: operation, error_type: error_type.to_s)
        end

        # Matches the leftmost structural segment and stops there. A secret may
        # legally be named `sys` or `auth`, so searching the whole path would let
        # a secret name decide the label.
        def operation_for(path)
          segments = path.to_s.split('/')
          index = segments.index { |segment| STRUCTURAL_SEGMENTS.include?(segment) }

          return 'other' unless index

          case segments[index]
          when 'sys' then sys_operation(segments[index + 1])
          when 'auth' then auth_operation(segments.drop(index + 1))
          else "kv/#{segments[index]}"
          end
        end

        private

        def sys_operation(endpoint)
          SYS_ENDPOINTS.include?(endpoint) ? "sys/#{endpoint}" : 'sys/other'
        end

        def auth_operation(segments)
          endpoint = segments.find { |segment| AUTH_ENDPOINTS.include?(segment) }

          endpoint ? "auth/#{endpoint}" : 'auth/other'
        end

        def call_duration
          ::Gitlab::SafeRequestStore[CALL_DURATION] || 0
        end

        def increment_request_count
          ::Gitlab::SafeRequestStore[REQUEST_COUNT] ||= 0
          ::Gitlab::SafeRequestStore[REQUEST_COUNT] += 1
        end

        def add_duration(duration)
          ::Gitlab::SafeRequestStore[CALL_DURATION] ||= 0
          ::Gitlab::SafeRequestStore[CALL_DURATION] += duration
        end

        def requests_total
          @requests_total ||=
            ::Gitlab::Metrics.counter(
              :gitlab_openbao_requests_total,
              'OpenBao HTTP requests made by Rails'
            )
        end

        def request_duration_seconds
          @request_duration_seconds ||=
            ::Gitlab::Metrics.histogram(
              :gitlab_openbao_request_duration_seconds,
              'OpenBao HTTP request duration measured from Rails',
              {},
              DURATION_BUCKETS
            )
        end

        # A sibling counter rather than a third value on `outcome`: splitting
        # `outcome` would leave `outcome="error"` matching no series and silence
        # anything already alerting on it.
        def request_errors_total
          @request_errors_total ||=
            ::Gitlab::Metrics.counter(
              :gitlab_openbao_request_errors_total,
              'OpenBao HTTP request failures made by Rails, by fault type'
            )
        end
      end
    end
  end
end
