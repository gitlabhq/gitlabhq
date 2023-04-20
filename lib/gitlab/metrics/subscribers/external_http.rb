# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total time spent in external HTTP
      # See more at https://gitlab.com/gitlab-org/labkit-ruby/-/blob/v0.14.0/lib/gitlab-labkit.rb#L18
      class ExternalHttp < ActiveSupport::Subscriber
        attach_to :external_http

        DEFAULT_STATUS_CODE = 'undefined'

        DETAIL_STORE = :external_http_detail_store
        COUNTER = :external_http_count
        DURATION = :external_http_duration_s
        SLOW_REQUESTS = :external_http_slow_requests

        THRESHOLD_SLOW_REQUEST_S = 5.0
        MAX_SLOW_REQUESTS = 10

        def self.detail_store
          ::Gitlab::SafeRequestStore[DETAIL_STORE] ||= []
        end

        def self.duration
          Gitlab::SafeRequestStore[DURATION].to_f
        end

        def self.request_count
          Gitlab::SafeRequestStore[COUNTER].to_i
        end

        def self.slow_requests
          Gitlab::SafeRequestStore[SLOW_REQUESTS]
        end

        def self.top_slowest_requests
          requests = slow_requests

          return unless requests.present?

          requests.sort_by { |req| req[:duration_s] }.reverse.first(MAX_SLOW_REQUESTS)
        end

        def self.payload
          {
            COUNTER => request_count,
            DURATION => duration,
            SLOW_REQUESTS => top_slowest_requests
          }.compact
        end

        def request(event)
          payload = event.payload
          add_to_detail_store(event.time, payload)
          add_to_request_store(payload)
          expose_metrics(payload)
        end

        private

        def current_transaction
          ::Gitlab::Metrics::WebTransaction.current || ::Gitlab::Metrics::BackgroundTransaction.current
        end

        def add_to_detail_store(start, payload)
          return unless Gitlab::PerformanceBar.enabled_for_request?

          self.class.detail_store << {
            start: start,
            duration: payload[:duration],
            scheme: payload[:scheme],
            method: payload[:method],
            host: payload[:host],
            port: payload[:port],
            path: payload[:path],
            query: payload[:query],
            code: payload[:code],
            exception_object: payload[:exception_object],
            backtrace: Gitlab::BacktraceCleaner.clean_backtrace(caller)
          }
        end

        def add_to_request_store(payload)
          return unless Gitlab::SafeRequestStore.active?

          Gitlab::SafeRequestStore[COUNTER] = Gitlab::SafeRequestStore[COUNTER].to_i + 1
          Gitlab::SafeRequestStore[DURATION] = Gitlab::SafeRequestStore[DURATION].to_f + payload[:duration].to_f

          if payload[:duration].to_f > THRESHOLD_SLOW_REQUEST_S
            Gitlab::SafeRequestStore[SLOW_REQUESTS] ||= []
            Gitlab::SafeRequestStore[SLOW_REQUESTS] << {
              method: payload[:method],
              host: payload[:host],
              port: payload[:port],
              path: payload[:path],
              duration_s: payload[:duration].to_f.round(3)
            }
          end
        end

        def expose_metrics(payload)
          return unless current_transaction

          labels = { method: payload[:method], code: payload[:code] || DEFAULT_STATUS_CODE }

          current_transaction.increment(:gitlab_external_http_total, 1, labels) do
            docstring 'External HTTP calls'
            label_keys labels.keys
          end

          current_transaction.observe(:gitlab_external_http_duration_seconds, payload[:duration]) do
            docstring 'External HTTP time'
            buckets [0.001, 0.01, 0.1, 1.0, 2.0, 5.0]
          end

          if payload[:exception_object].present?
            current_transaction.increment(:gitlab_external_http_exception_total, 1) do
              docstring 'External HTTP exceptions'
            end
          end
        end
      end
    end
  end
end
