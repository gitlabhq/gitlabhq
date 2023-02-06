# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      class Ldap < ActiveSupport::Subscriber
        # This namespace is configured in the Net::LDAP library, and appears
        # at the end of the event key, e.g. `open.net_ldap`
        attach_to :net_ldap

        COUNTER = :net_ldap_count
        DURATION = :net_ldap_duration_s

        # Assembled from methods that are instrumented inside Net::LDAP
        OBSERVABLE_EVENTS = %i[
          open
          bind
          add
          modify
          modify_password
          rename
          delete
          search
        ].freeze

        class << self
          # @return [Integer] the total number of LDAP requests
          def count
            Gitlab::SafeRequestStore[COUNTER].to_i
          end

          # @return [Float] the total duration spent on LDAP requests
          def duration
            Gitlab::SafeRequestStore[DURATION].to_f
          end

          # Used in Gitlab::InstrumentationHelper to merge the LDAP stats
          # into the log output
          #
          # @return [Hash<Integer, Float>] a hash of the stored statistics
          def payload
            {
              net_ldap_count: count,
              net_ldap_duration_s: duration
            }
          end
        end

        # Called when an event is triggered in ActiveSupport::Notifications
        #
        # This method is aliased to the various events triggered by the
        # Net::LDAP library, as the method will be called by those names
        # when triggered.
        #
        # It stores statistics in the request for output to logs, and also
        # resubmits the event data into Prometheus for monitoring purposes.
        def observe_event(event)
          add_to_request_store(event)
          expose_metrics(event)
        end

        OBSERVABLE_EVENTS.each do |event|
          alias_method event, :observe_event
        end

        private

        def current_transaction
          ::Gitlab::Metrics::WebTransaction.current || ::Gitlab::Metrics::BackgroundTransaction.current
        end

        # Track these events as statistics for the current requests, for logging purposes
        def add_to_request_store(event)
          return unless Gitlab::SafeRequestStore.active?

          Gitlab::SafeRequestStore[COUNTER] = self.class.count + 1
          Gitlab::SafeRequestStore[DURATION] = self.class.duration + convert_to_seconds(event.duration)
        end

        # Converts the observed events into Prometheus metrics
        def expose_metrics(event)
          return unless current_transaction

          # event.name will be, for example, `search.net_ldap`
          # and so we only want the first part, which is the
          # true name of the event
          labels = { name: event.name.split(".").first }
          duration = convert_to_seconds(event.duration)

          current_transaction.increment(:gitlab_net_ldap_total, 1, labels) do
            docstring 'Net::LDAP calls'
            label_keys labels.keys
          end

          current_transaction.observe(:gitlab_net_ldap_duration_seconds, duration, labels) do
            docstring 'Net::LDAP time'
            buckets [0.001, 0.01, 0.1, 1.0, 2.0, 5.0]
            label_keys labels.keys
          end
        end

        def convert_to_seconds(duration_f)
          (BigDecimal(duration_f.to_s) / BigDecimal("1000.0")).to_f
        end
      end
    end
  end
end
