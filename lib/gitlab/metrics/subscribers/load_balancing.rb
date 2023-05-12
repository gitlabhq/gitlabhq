# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      class LoadBalancing < ActiveSupport::Subscriber
        attach_to :load_balancing

        PROMETHEUS_COUNTER = :gitlab_transaction_caught_up_replica_pick_count_total
        LOG_COUNTERS = { true => :caught_up_replica_pick_ok, false => :caught_up_replica_pick_fail }.freeze

        def caught_up_replica_pick(event)
          return unless Gitlab::SafeRequestStore.active?

          result = event.payload[:result]
          counter_name = counter(result)

          increment(counter_name)
        end

        # we want to update Prometheus counter after the controller/action are set
        def web_transaction_completed(_event)
          return unless Gitlab::SafeRequestStore.active?

          LOG_COUNTERS.keys.each { |result| increment_prometheus_for_result_label(result) }
        end

        def self.load_balancing_payload
          return {} unless Gitlab::SafeRequestStore.active?

          {}.tap do |payload|
            LOG_COUNTERS.values.each do |counter|
              value = Gitlab::SafeRequestStore[counter]

              payload[counter] = value.to_i if value
            end
          end
        end

        private

        def increment(counter)
          Gitlab::SafeRequestStore[counter] = Gitlab::SafeRequestStore[counter].to_i + 1
        end

        def increment_prometheus_for_result_label(label_value)
          counter_name = counter(label_value)
          return unless (counter_value = Gitlab::SafeRequestStore[counter_name])

          increment_prometheus(labels: { result: label_value }, value: counter_value.to_i)
        end

        def increment_prometheus(labels:, value:)
          current_transaction&.increment(PROMETHEUS_COUNTER, value, labels) do
            docstring 'Caught up replica pick result'
            label_keys labels.keys
          end
        end

        def counter(result)
          LOG_COUNTERS[result]
        end

        def current_transaction
          ::Gitlab::Metrics::WebTransaction.current
        end
      end
    end
  end
end
