# frozen_string_literal: true

module Gitlab
  module Metrics
    module DatabaseTransactionSlis
      REQUEST_STORE_KEY = :txn_duration

      DEFAULT_DURATION_THRESHOLD = 1
      THRESHOLDS = { 'main' => 2.0, 'ci' => 2.5 }.freeze

      class << self
        def initialize_slis!(possible_labels)
          Gitlab::Metrics::Sli::Apdex.initialize_sli(:db_transaction, possible_labels)
        end

        def record_txn_apdex(labels, txn_durations)
          threshold = THRESHOLDS.fetch(labels[:db_config_name], DEFAULT_DURATION_THRESHOLD)

          Gitlab::Metrics::Sli::Apdex[:db_transaction].increment(
            labels: labels,
            success: txn_durations < threshold
          )
        end
      end
    end
  end
end
