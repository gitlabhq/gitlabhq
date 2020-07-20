# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking the total query duration of a transaction.
      class ActiveRecord < ActiveSupport::Subscriber
        include Gitlab::Metrics::Methods
        attach_to :active_record

        IGNORABLE_SQL = %w{BEGIN COMMIT}.freeze
        DB_COUNTERS = %i{db_count db_write_count db_cached_count}.freeze

        def sql(event)
          return unless current_transaction

          payload = event.payload

          return if payload[:name] == 'SCHEMA' || IGNORABLE_SQL.include?(payload[:sql])

          self.class.gitlab_sql_duration_seconds.observe(current_transaction.labels, event.duration / 1000.0)

          increment_db_counters(payload)
        end

        def self.db_counter_payload
          return {} unless Gitlab::SafeRequestStore.active?

          DB_COUNTERS.map do |counter|
            [counter, Gitlab::SafeRequestStore[counter].to_i]
          end.to_h
        end

        private

        define_histogram :gitlab_sql_duration_seconds do
          docstring 'SQL time'
          base_labels Transaction::BASE_LABELS
          buckets [0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
        end

        def select_sql_command?(payload)
          payload[:sql].match(/\A((?!(.*[^\w'"](DELETE|UPDATE|INSERT INTO)[^\w'"])))(WITH.*)?(SELECT)((?!(FOR UPDATE|FOR SHARE)).)*$/i)
        end

        def increment_db_counters(payload)
          increment(:db_count)

          if payload.fetch(:cached, payload[:name] == 'CACHE')
            increment(:db_cached_count)
          end

          increment(:db_write_count) unless select_sql_command?(payload)
        end

        def increment(counter)
          current_transaction.increment(counter, 1)

          if Gitlab::SafeRequestStore.active?
            Gitlab::SafeRequestStore[counter] = Gitlab::SafeRequestStore[counter].to_i + 1
          end
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
