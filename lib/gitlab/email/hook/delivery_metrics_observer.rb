# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      class DeliveryMetricsObserver
        extend Gitlab::Utils::StrongMemoize

        def self.delivering_email(_message)
          delivery_attempts_counter.increment
        end

        def self.delivered_email(_message)
          delivered_emails_counter.increment
        end

        def self.delivery_attempts_counter
          strong_memoize(:delivery_attempts_counter) do
            Gitlab::Metrics.counter(:gitlab_emails_delivery_attempts_total,
              'Counter of total emails delivery attempts')
          end
        end

        def self.delivered_emails_counter
          strong_memoize(:delivered_emails_counter) do
            Gitlab::Metrics.counter(:gitlab_emails_delivered_total,
              'Counter of total emails delievered')
          end
        end
      end
    end
  end
end
