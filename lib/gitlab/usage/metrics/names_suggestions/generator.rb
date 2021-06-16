# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module NamesSuggestions
        class Generator < ::Gitlab::UsageData
          class << self
            def generate(key_path)
              uncached_data.deep_stringify_keys.dig(*key_path.split('.'))
            end

            private

            def count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
              Gitlab::Usage::Metrics::NameSuggestion.for(:count, column: column, relation: relation)
            end

            def distinct_count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
              Gitlab::Usage::Metrics::NameSuggestion.for(:distinct_count, column: column, relation: relation)
            end

            def redis_usage_counter
              Gitlab::Usage::Metrics::NameSuggestion.for(:redis)
            end

            def alt_usage_data(*)
              Gitlab::Usage::Metrics::NameSuggestion.for(:alt)
            end

            def redis_usage_data_totals(counter)
              counter.fallback_totals.transform_values { |_| Gitlab::Usage::Metrics::NameSuggestion.for(:redis) }
            end

            def sum(relation, column, *rest)
              Gitlab::Usage::Metrics::NameSuggestion.for(:sum, column: column, relation: relation)
            end

            def estimate_batch_distinct_count(relation, column = nil, *rest)
              Gitlab::Usage::Metrics::NameSuggestion.for(:estimate_batch_distinct_count, column: column, relation: relation)
            end

            def add(*args)
              "add_#{args.join('_and_')}"
            end
          end
        end
      end
    end
  end
end
